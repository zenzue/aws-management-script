#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
SPIN='\033[1;34m'
NORMAL='\033[0m'
BOLD='\033[1m'

spinner=( '|' '/' '-' '\\' )

function spinning() {
    pid=$!
    i=0
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\r${SPIN}${spinner[$i]}${NC}"
        sleep .1
    done
    printf "\r"
}

function reset_terminal() {
    tput sgr0
    tput clear
}

function matrix_effect {
    local cols=$(tput cols)
    local lines=$(tput lines)

    tput civis

    declare -A rain
    for ((i=1; i<=cols; i++)); do
        rain[$i]=$((RANDOM % lines + 1))
    done

    while true; do
        local x=$((RANDOM % cols + 1))
        local y=${rain[$x]}

        tput cup $y $x

        echo -en "${GREEN}${BOLD}$(printf "%c" $(($RANDOM % 93 + 33)))${NC}"

        ((rain[$x]++))

        if [ ${rain[$x]} -ge $lines ]; then
            rain[$x]=0
        fi

        sleep 0.02
    done

    tput sgr0
    tput cnorm
}

function goodbye_message {
    sleep 5
    pkill -P $$
    reset_terminal
    echo -e "${RED}Bye Bye${NC}"
    sleep 2
}

function main_menu {
    clear
    echo -e "${GREEN}AWS Management Console by w01f${NC}"
    echo -e "${YELLOW}Select an option:${NC}"
    echo -e "${RED}1. Check Running Instances${NC}"
    echo -e "${RED}2. Check Security Group Rules${NC}"
    echo -e "${RED}3. Check Instance Status by ID${NC}"
    echo -e "${RED}4. Check All Instances (Including Stopped)${NC}"
    echo -e "${RED}5. Stop, Start, Restart Instance by ID${NC}"
    echo -e "${RED}6. DevOps Features${NC}"
    echo -e "${RED}7. Check EBS Volumes${NC}"
    echo -e "${RED}8. Domain Management${NC}"
    echo -e "${RED}9. Exit${NC}"
    read -p "Enter your choice: " choice

    case $choice in
        1) check_running_instances ;;
        2) check_security_rules ;;
        3) check_instance_status ;;
        4) check_all_instances ;;
        5) manage_instance ;;
        6) devops_features ;;
        7) check_volumes ;;
        8) domain_management ;;
        9) 
            matrix_effect &
            goodbye_message
            exit 0
            ;;
        *) echo -e "${YELLOW}Invalid choice. Try again.${NC}"; sleep 2; main_menu ;;
    esac
}

function check_running_instances {
    echo -e "${GREEN}Fetching all running instances with IP addresses and running hours...${NC}"
    aws ec2 describe-instances --query "Reservations[*].Instances[*].{Instance_ID:InstanceId,State:State.Name,Public_IP:PublicIpAddress,LaunchTime:LaunchTime}" --filters "Name=instance-state-name,Values=running" --output table | 
    awk 'BEGIN{FS="\t"; OFS="\t"}; NR>1{$5 = int((systime() - mktime(gensub(/[:-]/," ","g",substr($4,1,19))))/3600) " hrs"} 1' &
    spinning
    pause
}

function check_security_rules {
    echo -e "${GREEN}Fetching all available security groups...${NC}"
    mapfile -t security_groups < <(aws ec2 describe-security-groups --query "SecurityGroups[*].[GroupId,GroupName,Description]" --output text)
    echo -e "${YELLOW}Please select a security group to view details:${NC}"

    select sg_option in "${security_groups[@]}" "Quit"; do
        case $sg_option in
            * )
                sg_id=$(echo $sg_option | awk '{print $1}')
                echo -e "${GREEN}Fetching rules for Security Group ID: ${sg_id}...${NC}"
                aws ec2 describe-security-groups --group-ids $sg_id --query 'SecurityGroups[*].{ID:GroupId, InboundRules:IpPermissions, OutboundRules:IpPermissionsEgress}' --output table &
                spinning
                pause
                break
                ;;
            "Quit" )
                echo "Exiting to main menu..."
                return
                ;;
            * )
                echo "Invalid option, try again."
                ;;
        esac
    done
}

function check_instance_status {
    echo -e "${GREEN}Fetching running instances for selection...${NC}"
    mapfile -t instance_details < <(aws ec2 describe-instances --query "Reservations[*].Instances[*].[InstanceId, Tags[?Key=='Name'].Value | [0], State.Name, PublicIpAddress]" --filters "Name=instance-state-name,Values=running" --output text)
    select opt in "${instance_details[@]}" "Quit"; do
        case $opt in
            * )
                instance_id=$(echo $opt | awk '{print $1}')
                echo -e "${GREEN}Fetching details for Instance ID: $instance_id...${NC}"
                aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress,LaunchTime]" --output table &
                spinning
                pause
                break
                ;;
            "Quit" )
                echo "Exiting to main menu..."
                return
                ;;
            * )
                echo "Invalid option, try again."
                ;;
        esac
    done
}

function check_all_instances {
    echo -e "${GREEN}Fetching all instances...${NC}"
    aws ec2 describe-instances --query "Reservations[*].Instances[*].[InstanceId,State.Name,Tags[?Key=='Name'].Value | [0]]" --output table &
    spinning
    pause
}

function manage_instance {
    echo -e "${GREEN}Fetching running instances for operation...${NC}"
    mapfile -t instance_details < <(aws ec2 describe-instances --query "Reservations[*].Instances[*].[InstanceId, Tags[?Key=='Name'].Value | [0], State.Name, PublicIpAddress]" --filters "Name=instance-state-name,Values=running" --output text)
    echo -e "${YELLOW}Please select an instance for operation:${NC}"
    select opt in "${instance_details[@]}" "Quit"; do
        case $opt in
            * )
                instance_id=$(echo $opt | awk '{print $1}')
                echo -e "${GREEN}Selected Instance ID: $instance_id${NC}"
                echo -e "${YELLOW}Choose an operation: 1) Stop  2) Start  3) Restart  4) Force Stop  5) Cancel${NC}"
                read -p "Enter your choice: " operation_choice

                case $operation_choice in
                    1)
                        aws ec2 stop-instances --instance-ids $instance_id &
                        echo -e "${GREEN}Stopping instance...${NC}"
                        ;;
                    2)
                        aws ec2 start-instances --instance-ids $instance_id &
                        echo -e "${GREEN}Starting instance...${NC}"
                        ;;
                    3)
                        aws ec2 reboot-instances --instance-ids $instance_id &
                        echo -e "${GREEN}Restarting instance...${NC}"
                        ;;
                    4)
                        aws ec2 stop-instances --instance-ids $instance_id --force &
                        echo -e "${GREEN}Force stopping instance...${NC}"
                        ;;
                    5)
                        echo -e "${YELLOW}Canceling operation...${NC}"
                        ;;
                    *)
                        echo -e "${RED}Invalid operation selected.${NC}"
                        ;;
                esac
                spinning
                pause
                break
                ;;
            "Quit" )
                echo "Exiting to main menu..."
                return
                ;;
            * )
                echo "Invalid option, try again."
                ;;
        esac
    done
}

function devops_features {
    echo -e "${YELLOW}Select DevOps Feature to Execute:${NC}"
    echo "1. Create Snapshot"
    echo "2. Set CPU Utilization Alarm"
    echo "3. Scale EC2 Instances"
    echo "4. Deploy Application"
    echo "5. Perform Security Audit"
    read -p "Enter feature number: " devops_feature

    case $devops_feature in
        1)
            read -p "Enter Volume ID: " volume_id
            aws ec2 create-snapshot --volume-id $volume_id --description "Snapshot on $(date +%Y-%m-%d)" &
            ;;
        2)
            read -p "Enter Instance ID for Monitoring: " instance_id
            aws cloudwatch put-metric-alarm --alarm-name "EC2 Instance Health Check" --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 300 --threshold 80 --comparison-operator GreaterThanThreshold --dimensions Name=InstanceId,Value=$instance_id --evaluation-periods 2 --alarm-actions <sns-topic-arn> --unit Percent &
            ;;
        3)
            read -p "Enter Auto Scaling Group Name and Desired Capacity: " asg_name capacity
            aws autoscaling set-desired-capacity --auto-scaling-group-name $asg_name --desired-capacity $capacity &
            ;;
        4)
            echo "Trigger deployment via CI/CD tool..." &
            ;;
        5)
            echo "Performing security audits..." &
            aws ec2 describe-security-groups --query 'SecurityGroups[*].[GroupId, IpPermissions[*].IpRanges]' --output text | grep "0.0.0.0/0" &
            ;;
        *)
            echo -e "${YELLOW}Invalid feature selected.${NC}"
            ;;
    esac
    spinning
    pause
}

function check_volumes {
    echo -e "${GREEN}Listing all EBS volumes...${NC}"
    aws ec2 describe-volumes --query "Volumes[*].{ID:VolumeId,State:State,Type:VolumeType,Size:Size}" --output table &
    spinning
    pause
}

function domain_management {
    echo -e "${YELLOW}Domain Management:${NC}"
    echo "1. List Hosted Zones"
    echo "2. List DNS Records for a Zone"
    echo "3. Create or Update DNS Record"
    echo "4. Delete DNS Record"
    read -p "Select an option for domain management: " domain_choice

    case $domain_choice in
        1) list_hosted_zones ;;
        2) list_dns_records ;;
        3) create_update_dns_record ;;
        4) delete_dns_record ;;
        *) echo -e "${YELLOW}Invalid option. Returning to main menu...${NC}"; main_menu ;;
    esac
}

function list_hosted_zones {
    echo -e "${GREEN}Listing all hosted zones...${NC}"
    aws route53 list-hosted-zones --output table &
    spinning
    pause
}

function list_dns_records {
    read -p "Enter Hosted Zone ID: " zone_id
    echo -e "${GREEN}Listing DNS records for zone ID: ${zone_id}...${NC}"
    aws route53 list-resource-record-sets --hosted-zone-id $zone_id --output table &
    spinning
    pause
}

function create_update_dns_record {
    echo -e "${YELLOW}Create or Update a DNS Record:${NC}"
    read -p "Enter Hosted Zone ID: " zone_id
    read -p "Enter Record Name (e.g., example.com): " record_name
    read -p "Enter Record Type (e.g., A, CNAME, MX, etc.): " record_type
    read -p "Enter Record Value: " record_value
    read -p "Enter TTL (e.g., 300): " ttl

    cat <<EOF > change-batch.json
{
    "Changes": [{
        "Action": "UPSERT",
        "ResourceRecordSet": {
            "Name": "$record_name",
            "Type": "$record_type",
            "TTL": $ttl,
            "ResourceRecords": [{ "Value": "$record_value" }]
        }
    }]
}
EOF

    aws route53 change-resource-record-sets --hosted-zone-id $zone_id --change-batch file://change-batch.json &
    spinning
    echo -e "${GREEN}DNS record updated/created successfully.${NC}"
    pause
}

function delete_dns_record {
    echo -e "${YELLOW}Delete a DNS Record:${NC}"
    read -p "Enter Hosted Zone ID: " zone_id
    read -p "Enter Record Name (e.g., example.com): " record_name
    read -p "Enter Record Type (e.g., A, CNAME, etc.): " record_type

    cat <<EOF > change-batch.json
{
    "Changes": [{
        "Action": "DELETE",
        "ResourceRecordSet": {
            "Name": "$record_name",
            "Type": "$record_type",
            "TTL": 300,
            "ResourceRecords": [{ "Value": "Record Value to be deleted" }]
        }
    }]
}
EOF

    aws route53 change-resource-record-sets --hosted-zone-id $zone_id --change-batch file://change-batch.json &
    spinning
    echo -e "${GREEN}DNS record deleted successfully.${NC}"
    pause
}

function pause {
    echo -e "${YELLOW}Press any key to return to main menu...${NC}"
    read -n 1
    main_menu
}

main_menu