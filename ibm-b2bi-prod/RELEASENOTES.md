# What's new in Helm Charts Version 2.1.3 for IBM Sterling B2B Integrator Enterprise Edition v6.1.2.2
* Support for PowerLE (ppc64le) architecture
* Separate container image for database setup job
* Support for configuring init container for external resources like db driver jar, standards jar, seas integration jars and so on.
* Support for Performance Tuning Wizard updates by using the tuning jar utility.
* API auto scaling enhancements and performance improvements.
* Support for restricted security context in OpenShift.
* Support for explicit license acceptance with form view deployment from OpenShift Developer Catalog. For details, refer to Using Red Hat OpenShift Developer Catalog.
* Certified Container support for Oracle CDB.
* Support for auto-configuration of GC Policy.
* Certified container support for integrations with MQ Operators and CD certified container.
* Support for overriding Liberty server.xml and jvm options parameters.
* Support for pre-defined PVCs for resources, logs and documents.
* Support for restart cluster via configuration
* Enhanced security with out of the box deny all external ingress and egress network policies with option to define additional custom policies


# Breaking Changes
Rolling upgrades for product version v6.1.0.0 will be supported but for product versions earlier than v6.1.0.0 installed using IIM, Docker or Certified Container will not be supported.

# DB Changes (refer Version History section below)
If its fresh install =>
	Set dataSetup.enabled to true and dataSetup.upgrade to false in values.yaml
In case of upgrade =>
	If DB Changes are introduced, then set dataSetup.enabled to true and dataSetup.upgrade to true
	If DB Changes are not introduced, then set dataSetup.enabled to false and dataSetup.upgrade to true


# Documentation
Check the README file provided with the chart for detailed installation instructions.

# Fixes
N/A

# Prerequisites
Please refer prerequisites section from README.md

# Version History

| Chart | Date | Kubernetes Version Required | Breaking Changes | Details | DB Changes |
| ----- | ---- | --------------------------- | ---------------- | ------- | ---------- |
| 2.0.1   | December 18, 2020 | >=1.14.6 | N  | Fix pack release upgrade for IBM Sterling B2B Integrator Certified Containers | N | 
| 2.0.2   | March 19, 2021 | >=1.14.6 | N  | Fix pack release upgrade for IBM Sterling B2B Integrator Certified Containers | N |
| 2.0.3   | June 29, 2021 | >=1.17 | N  | Fix pack release upgrade for IBM Sterling B2B Integrator Certified Containers | N |
| 2.0.4   | Novemeber 10, 2021 | >=1.17 | N  | Fix pack release upgrade for IBM Sterling B2B Integrator Certified Containers | N |
| 2.0.5   | January 14, 2022 | >=1.17 | N  | iFix release upgrade for IBM Sterling B2B Integrator Certified Containers | N |
| 2.0.6   | May 13, 2022 | >=1.17 | N  | Fix pack release upgrade for IBM Sterling B2B Integrator Certified Containers | N |
| 2.0.7   | July 07, 2022 | >=1.17 | N  | iFix release upgrade for IBM Sterling B2B Integrator Certified Containers | N |
| 2.1.0   | Sep 30, 2022  | >=1.21 | N | Mod release upgrade for IBM Sterling B2B Integrator Certified Containers | Y |
| 2.1.1   | Dec 16, 2022  | >=1.21 | N | Fix pack release upgrade for IBM Sterling B2B Integrator Certified Containers | Y |
| 2.1.2   | Mar 03, 2023  | >=1.23 | N | Fix pack release upgrade for IBM Sterling B2B Integrator Certified Containers | Y |
| 2.1.3   | Mar 27, 2023  | >=1.23 | N | Fix pack release upgrade for IBM Sterling B2B Integrator Certified Containers | Y |
