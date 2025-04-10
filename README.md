# AWS Management Script

This repository contains a script designed to simplify the management of AWS resources, including EC2 instances and Route 53 domain records. The script provides a command-line interface for performing a variety of AWS operations directly from your terminal.

## Features

- **EC2 Management**: List, start, stop, and restart EC2 instances.
- **Security Group Management**: View and modify security group rules.
- **EBS Volumes**: List all Elastic Block Store (EBS) volumes.
- **Domain Management**: Manage DNS records and hosted zones through AWS Route 53.
- **DevOps Utilities**: Includes features such as creating snapshots, managing auto-scaling, and performing security audits.

## Usage

To use the script, clone this repository and navigate to the directory containing the script.

```bash
git clone https://github.com/zenzue/aws-management-script.git
cd aws-management-script
```

Make the script executable:

```bash
chmod +x aws_manage.sh
```

Run the script:

```bash
./aws_manage.sh
```

Follow the on-screen prompts to select from the available management options.

## Requirements

- AWS CLI must be installed and configured with the necessary permissions to manage the resources.
- This script is designed to run on any Unix-like operating system.

## Author

**w01f [Aung Myat Thu]**

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Contributions

Contributions are welcome. Please open an issue to discuss your ideas or submit a pull request.

## Acknowledgments

- Thanks to the AWS documentation for providing clear API documentation.
- Thanks to all contributors who help in maintaining and enhancing this project.
