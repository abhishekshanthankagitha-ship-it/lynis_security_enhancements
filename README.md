# Lynis Security Enhancements

### Custom Bash Scripts for Linux Security Auditing

This project implements two custom Bash security auditing scripts inspired by Lynis security auditing objectives. The scripts examine Linux login banner configurations and NTP configuration and synchronization status.

## Project Objectives

- Assess login banner security configurations.
- Identify missing or empty login banner files.
- Validate required security warning keywords.
- Detect potentially sensitive credential-like assignments in banner files.
- Examine NTP configuration and runtime information.
- Identify recognized NTP server hostnames.
- Check time synchronization service status.
- Verify system clock synchronization.

## Project Structure

```text
lynis_security_enhancements/
├── README.md
├── scripts/
│   ├── custom_login_banner.sh
│   └── custom_ntp_security.sh
└── results/
    ├── login_banner_output.txt
    └── ntp_security_output.txt
