# HelloID-Conn-Prov-Source-Ultipro

| :information_source: Information |
|:---------------------------|
| This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements.       |

<br />

<p align="center">
  <img src="Assets/Logo.jpg">
</p>

<!-- TABLE OF CONTENTS -->
## Table of Contents
* [Getting Started](#getting-started)
* [Requirements](#Requirements)
* [Setup the PowerShell connector](#setup-the-powershell-connector)
* [Sample VPN Scripts](#sample-vpn-scripts)

<!-- GETTING STARTED -->
## Getting Started
By using this connector you will have the ability to import data into HelloID:
* Employee Demographics
* Employee Phones
* Employment Details
* Company Information

## Requirements
- UltiPro service account must have "View" role for the "Employee Person Details" Web Service - This provides the Demographic details, such as Firstname, Lastname, etc.
- UltiPro service account must have "View" role for the "Personnel Integration" Web Service - This provides the Employment Details, such as Title, Hire Date, etc.
- UltiPro Service account must have "View" role for the "Company Configuration Integration" Web Service - This provides Org Unit, Company, and Location details (ie: Addresses and names)
- UltiPro Service account must have access to the 'Employee Phone Information' web service - This provides access to the Mobile Number data


## Setup the PowerShell connector
1. Add a new 'Source System' to HelloID and make sure to import all the necessary files.

    - [ ] configuration.json
    - [ ] persons.ps1
    - [ ] departments.ps1


2. Fill in the required fields on the 'Configuration' tab.

# HelloID Docs
The official HelloID documentation can be found at: https://docs.helloid.com/
