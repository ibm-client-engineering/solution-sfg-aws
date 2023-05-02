# (C) Copyright 2019-2022 Syncsort Incorporated. All rights reserved.

{{/*
A function to validate if passed parameter is a valid integer
*/}}
{{- define "integerValidation" -}}
{{- $type := kindOf . -}}
{{- if or (eq $type "float64") (eq $type "int") -}}
    {{- $isIntegerPositive := include "isIntegerPositive" . -}}
    {{- if eq $isIntegerPositive "true" -}}
    	true
    {{- else -}}
    	false
    {{- end -}}	
{{- else -}}
    false
{{- end -}}
{{- end -}}

{{/*
A function to validate if passed integer is non negative
*/}}
{{- define "isIntegerPositive" -}}
{{- $inputInt := int64 . -}}
{{- if gt $inputInt -1 -}}
    true
{{- else -}}
    false
{{- end -}}
{{- end -}}

{{/*
A function to validate if passed parameter is a valid string
*/}}
{{- define "stringValidation" -}}
{{- $type := kindOf . -}}
{{- if or (eq $type "string") (eq $type "String") -}}
    true
{{- else -}}
    false
{{- end -}}
{{- end -}}

{{/*
A function to check for mandatory arguments
*/}}
{{- define "mandatoryArgumentsCheck" -}}
{{- if . -}}
    true
{{- else -}}
    false
{{- end -}}
{{- end -}}

{{/*
A function to check for port range
*/}}
{{- define "portRangeValidation" -}}
{{- $portNo := int64 . -}}
{{- if and (gt $portNo 0) (lt $portNo 65536) -}}
    true
{{- else -}}
    false
{{- end -}}
{{- end -}}

{{/*
A function to check if port is valid
*/}}
{{- define "isPortValid" -}}
{{- $result := include "integerValidation" . -}}
{{- if eq $result "true" -}}
	{{- $isPortValid := include "portRangeValidation" . -}}
	{{- if eq $isPortValid "true" -}}
	true
	{{- else -}}
	false
	{{- end -}}
{{- else -}}
	false
{{- end -}}
{{- end -}}

{{/*
A function to check if port range is valid
*/}}
{{- define "isPortRangeValid" -}}
{{- $result := false -}}
{{- $portRangeNumbers := split "-" . -}}
{{- $isPortRangeStartValid := include "isPortValid" ($portRangeNumbers._0|int) -}}
{{- if eq $isPortRangeStartValid "true" -}}
	{{- $isPortRangeEndValid := include "isPortValid" ($portRangeNumbers._1|int) -}}
	{{- if eq $isPortRangeEndValid "true" -}}
	{{- $isPortRangeOrderValid := ge ($portRangeNumbers._1|int) ($portRangeNumbers._0|int) -}}
	{{- if eq $isPortRangeOrderValid true -}}
	{{- $result = true -}}
	{{- end -}}
	{{- end -}}
{{- end -}}
{{- if eq $result true -}}
  true
{{- else -}}
  false
{{- end -}}
{{- end -}}

{{/*
A function to check if name is valid
*/}}
{{- define "isNameValid" -}}
{{- $result := regexMatch "[a-z0-9]([-a-z0-9]*[a-z0-9])?" . -}}
{{- if eq $result true -}}
  true
{{- else -}}
  false
{{- end -}}
{{- end -}}


{{/*
A function to check for validity of service ports
*/}}
{{- define "frontendServiceCheck" -}}
{{- $result := include "mandatoryArgumentsCheck" .type -}}
{{- if eq $result "false" -}}
{{- fail "frontendService.type cannot be empty" -}}
{{- end -}}
{{- $result := .type -}}
{{- if not (or (eq $result "NodePort") (eq $result "LoadBalancer") (eq $result "ClusterIP") (eq $result "ExternalName")) -}}
{{- fail "frontendService.type is not valid. Valid values are NodePort,LoadBalancer, ClusterIP or ExternalName" -}}
{{- end -}}
{{- if .sessionAffinityConfig.timeoutSeconds -}}
{{- $result := include "integerValidation" .sessionAffinityConfig.timeoutSeconds -}}
{{- if eq $result "false" -}}
{{- fail "Provide a valid value for frontendService.sessionAffinityConfig.timeoutSeconds" -}}
{{- end -}}
{{- end -}}
{{- $result := .externalTrafficPolicy -}}
{{- if not (or (eq $result "Cluster") (eq $result "Local")) -}}
{{- fail "frontendService.externalTrafficPolicy is not valid. Valid values are Cluster or Local" -}}
{{- end -}}
{{- include "servicePortCheck" .ports.http -}}
{{- if .ports.https }}
{{- include "servicePortCheck" .ports.https -}}
{{- end -}}
{{- range $i, $port := .extraPorts -}}
{{- include "servicePortCheck" $port -}}
{{- end -}}
{{- end -}}


{{- define "extraPVCvalidation" -}}
{{- $params := . -}}
{{- $extraPVC := (index $params 1) -}}
{{- $releaseNameSpace := (index $params 2) -}}
{{- range $i, $pvc := $extraPVC }}
{{- if empty ($pvc.mountPath) -}}
{{- fail  "extraPVCs mountPath cannot be null" -}}
{{- end -}}
{{- $isValid := $pvc.enableVolumeClaimPerPod | toString -}}
{{- if not ( or (eq $isValid "false") (eq $isValid "true")) -}}
{{- fail "Please provide a valid value for extraPVC.enableVolumeClaimPerPod. Value can be either true or false." -}}
{{- end -}}
{{- if $pvc.enableVolumeClaimPerPod }}
{{- $accessMode := $pvc.accessMode -}}
{{- if not ( or (eq $accessMode "ReadWriteOnce") (eq $accessMode "ReadWriteOncePod")) -}}
{{- fail "The supported values for extraPVCs.accessMode are only ReadWriteOnce or ReadWriteOncePod when extraPVCs.enableVolumeClaimPerPod is enabled" -}}
{{- end -}}
{{- end -}}
{{- if ($pvc.predefinedPVCName) }}
{{- $resourceexist := (empty (lookup "v1" "PersistentVolumeClaim" $releaseNameSpace $pvc.predefinedPVCName)) | ternary "false" "true"  }}
{{ if (eq $resourceexist "false") }}
{{- fail "Error: PVC extraPVCs predefinedPVCName not found in namespace.." -}}
{{- end -}}
{{- if ($pvc.enableVolumeClaimPerPod) -}}
{{- fail "Configuration for extraPVCs preDefinedPVCName is not applicable when extraPVCs.enableVolumeClaimPerPod is enabled." -}}
{{- end -}}
{{- else if ($pvc.name) }}
{{- $accessMode := $pvc.accessMode -}}
{{- if not ( or (eq $accessMode "ReadWriteOnce") (eq $accessMode "ReadWriteOncePod") (eq $accessMode "ReadOnlyMany") (eq $accessMode "ReadWriteMany") ) -}}
{{- fail "Please specify extraPVCs accessMode as one of these supported access mode - ReadWriteOnce | ReadOnlyMany | ReadWriteMany | ReadWriteOncePod" -}}
{{- end -}}
{{- else }}
{{- fail "Please specify extraPVCs name or extraPVCs predefinedPVCName" -}}
{{- end -}}
{{- end -}}
{{- end -}}


{{- define "backendServiceCheck" -}}
{{- $result := include "mandatoryArgumentsCheck" .type -}}
{{- if eq $result "false" -}}
{{- fail "backendService.type cannot be empty" -}}
{{- end -}}
{{- $result := .type -}}
{{- if not (or (eq $result "NodePort") (eq $result "LoadBalancer") (eq $result "ClusterIP") (eq $result "ExternalName")) -}}
{{- fail "backendService.type is not valid. Valid values are NodePort,LoadBalancer, ClusterIP or ExternalName" -}}
{{- end -}}
{{- $result := .sessionAffinity -}}
{{- if not (or (eq $result "ClientIP") (eq $result "None")) -}}
{{- fail "backendService.sessionAffinity is not valid. Valid values are ClientIP or None" -}}
{{- end -}}
{{- if (and (eq $result "ClientIP") (.sessionAffinityConfig.timeoutSeconds)) -}}
{{- $result := include "integerValidation" .sessionAffinityConfig.timeoutSeconds -}}
{{- if eq $result "false" -}}
{{- fail "Provide a valid value for backendService.sessionAffinityConfig.timeoutSeconds" -}}
{{- end -}}
{{- end -}}
{{- $result := .externalTrafficPolicy -}}
{{- if not (or (eq $result "Cluster") (eq $result "Local")) -}}
{{- fail "backendService.externalTrafficPolicy is not valid. Valid values are Cluster or Local" -}}
{{- end -}}
{{- range $i, $port := .ports -}}
{{- include "servicePortCheck" $port -}}
{{- end -}}
{{- range $i, $portRange := .portRanges -}}
{{- include "servicePortRangeCheck" $portRange -}}
{{- end -}}
{{- end -}}

{{/*
A function to check for validity of service ports
*/}}
{{- define "servicePortCheck" -}}
{{- $result := include "isPortValid" .port -}}
{{- if eq $result "false" -}}
{{- fail "Provide a valid value for port in service" -}}
{{- end -}}
{{- $result := include "isPortValid" .targetPort -}}
{{- if eq $result "false" -}}
{{- $nameCheck := include "isNameValid" .targetPort -}}
{{- if eq $nameCheck "false" -}}
{{- fail "Provide a valid value for targetPort in service" -}}
{{- end -}}
{{- end -}}

{{- $nodePortValue := .nodePort -}}
{{- if $nodePortValue -}}
{{- $result := include "isPortValid" .nodePort -}}
{{- if eq $result "false" -}}
{{- fail "Provide a valid value for nodePort in service" -}}
{{- end -}}
{{- end -}}

{{- $result := include "isNameValid" .name -}}
{{- if eq $result "false" -}}
{{- fail "Provide a valid value for name in service" -}}
{{- end -}}

{{- $result := .protocol -}}
{{- if $result -}}
{{- if not (or (eq $result "TCP") (eq $result "UDP") (eq $result "HTTP") (eq $result "SCTP") (eq $result "PROXY")) -}}
{{- fail "Provide a valid value for protocol in service. Valid values are TCP, UDP, HTTP, SCTP or PROXY" -}}
{{- end -}}
{{- end -}}

{{- end -}}

{{/*
A function to check for validity of service ports
*/}}
{{- define "servicePortRangeCheck" -}}

{{- $result := include "isPortRangeValid" .portRange -}}
{{- if eq $result "false" -}}
{{- fail "Provide a valid value for port range in service" -}}
{{- end -}}

{{- $result := include "isPortRangeValid" .targetPortRange -}}
{{- if eq $result "false" -}}
{{- fail "Provide a valid value for target port range in service" -}}
{{- end -}}

{{- if .nodePortRange -}}
{{- $result := include "isPortRangeValid" .nodePortRange -}}
{{- if eq $result "false" -}}
{{- fail "Provide a valid value for node port range in service" -}}
{{- end -}}
{{- end -}}

{{- $result := include "isNameValid" .name -}}
{{- if eq $result "false" -}}
{{- fail "Provide a valid value for name in service" -}}
{{- end -}}

{{- $result := .protocol -}}
{{- if $result -}}
{{- if not (or (eq $result "TCP") (eq $result "UDP") (eq $result "HTTP") (eq $result "SCTP") (eq $result "PROXY")) -}}
{{- fail "Provide a valid value for protocol in service. Valid values are TCP, UDP, HTTP, SCTP or PROXY" -}}
{{- end -}}
{{- end -}}

{{- end -}}

{{/*
A function to validate an email address
*/}}
{{- define "emailValidator" -}}
{{- $emailRegex := "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$" -}}
{{- $isValid := regexMatch $emailRegex . -}}
{{- if eq $isValid true -}}
	true
{{- else -}}
	false	
{{- end -}}
{{- end -}}

{{/*
A function to validate arch
*/}}
{{- define "archValidator" -}}
{{- $archList := list "0 - Do not use" "1 - Least preferred" "2 - No Preference" "3 - Most preferred" -}}
{{- $isValid := has . $archList -}}
{{- if eq $isValid true -}}
	true
{{- else -}}
	false	
{{- end -}}
{{- end -}}

{{/*
A function to validate the user or group name and ID
*/}}
{{- define "userOrGroupNameIDValidator" -}}
{{- $isInteger := include "integerValidation" . -}}
{{- if eq $isInteger "true" -}}
	true
{{- else -}}
	{{- $userOrGroupNameRegex := "^[a-z][-a-z0-9]*$" -}}
	{{- $isValid := regexMatch $userOrGroupNameRegex . -}}
	{{- if eq $isValid true -}}
		true
	{{- else -}}
		false
	{{- end -}}				
{{- end -}}
{{- end -}}

{{/*
Main function to test the input validations
*/}}

{{- define "validateInput" -}}

{{- $result := include "integerValidation" .Values.asi.replicaCount -}}
{{- if eq $result "false" -}}
{{- fail "Provide a valid value for .Values.asi.replicaCount" -}}
{{- end -}}

{{- $result := include "integerValidation" .Values.ac.replicaCount -}}
{{- if eq $result "false" -}}
{{- fail "Provide a valid value for .Values.ac.replicaCount" -}}
{{- end -}}

{{- $result := include "integerValidation" .Values.api.replicaCount -}}
{{- if eq $result "false" -}}
{{- fail "Provide a valid value for .Values.api.replicaCount" -}}
{{- end -}}

{{- $result := include "mandatoryArgumentsCheck" .Values.global.image.repository -}}
{{- if eq $result "false" -}}
{{- fail ".Values.global.image.repository cannot be empty." -}}
{{- end -}}

{{- if not .Values.global.image.digest -}}
{{- $result := include "mandatoryArgumentsCheck" .Values.global.image.tag -}}
{{- if eq $result "false" -}}
{{- fail "Please specify either .Values.global.image.tag or .Values.global.image.digest " -}}
{{- end -}}
{{- end -}}

{{- $result := include "mandatoryArgumentsCheck" .Values.global.image.pullPolicy -}}
{{- if eq $result "false" -}}
{{- fail ".Values.global.image.pullPolicy cannot be empty" -}}
{{- end -}}

{{- $isValid := include "archValidator" .Values.arch.amd64 -}}
{{- if eq $isValid "false" -}}
{{- fail "Please specify a valid preference for amd64 architecture - '0 - Do not use' | '1 - Least preferred' | '2 - No Preference' | '3 - Most preferred'" -}}
{{- end -}}

{{- $isValid := include "archValidator" .Values.arch.ppc64le -}}
{{- if eq $isValid "false" -}}
{{- fail "Please specify a valid preference for ppc64le architecture - '0 - Do not use' | '1 - Least preferred' | '2 - No Preference' | '3 - Most preferred'" -}}
{{- end -}}

{{- $isValid := include "archValidator" .Values.arch.s390x -}}
{{- if eq $isValid "false" -}}
{{- fail "Please specify a valid preference for s390x architecture - '0 - Do not use' | '1 - Least preferred' | '2 - No Preference' | '3 - Most preferred'" -}}
{{- end -}}

{{- $result := include "mandatoryArgumentsCheck" .Values.serviceAccount.name -}}
{{- if eq $result "false" -}}
{{- fail ".Values.serviceAccount.name cannot be empty" -}}
{{- end -}}

{{ if .Values.setupCfg.basePort }}
	{{- $result := include "isPortValid" .Values.setupCfg.basePort -}}
	{{- if eq $result "false" -}}
	{{- fail "Values.setupCfg.basePort field is not valid." -}}
	{{- end -}}
{{- end }}

{{- $isValid := .Values.dataSetup.enabled | toString -}}
{{- if not ( or (eq $isValid "false") (eq $isValid "true")) -}}
{{- fail "Please provide value for field Values.dataSetup.enabled. Value can be either true or false." -}}
{{- end -}}

{{- if eq $isValid "true" -}}

{{- $isValidUpdate := .Values.dataSetup.upgrade | toString -}}
{{- if not ( or (eq $isValidUpdate "false") (eq $isValidUpdate "true")) -}}
{{- fail "Please provide value for field Values.dataSetup.upgrade. Value can be either true or false." -}}
{{- end -}}

{{- $result := include "mandatoryArgumentsCheck" .Values.dataSetup.image.repository -}}
{{- if eq $result "false" -}}
{{- fail ".Values.dataSetup.image.repository cannot be empty." -}}
{{- end -}}

{{- if not .Values.dataSetup.image.digest -}}
{{- $result := include "mandatoryArgumentsCheck" .Values.dataSetup.image.tag -}}
{{- if eq $result "false" -}}
{{- fail ".Values.dataSetup.image.tag cannot be empty" -}}
{{- end -}}
{{- end -}}

{{- $result := include "mandatoryArgumentsCheck" .Values.dataSetup.image.pullPolicy -}}
{{- if eq $result "false" -}}
{{- fail ".Values.dataSetup.image.pullPolicy cannot be empty" -}}
{{- end -}}

{{- end -}}

{{- include "frontendServiceCheck" .Values.asi.frontendService -}}
{{- include "frontendServiceCheck" .Values.ac.frontendService -}}
{{- include "frontendServiceCheck" .Values.api.frontendService -}}

{{- include "backendServiceCheck" .Values.asi.backendService -}}
{{- include "backendServiceCheck" .Values.ac.backendService -}}

{{/*
{{- $result := .Values.readinessCheck.asiNodes.path -}}
{{- if not ( eq $result "/dashboard/") -}}
 	{{- fail "Provide a valid value for Values.readinessCheck.asiNodes.path. Applicable value is /dashboard/ " -}}
{{- end -}}

{{- $result := .Values.readinessCheck.asiNodes.scheme -}}
{{- if not (or (eq $result "HTTP") (eq $result "HTTPS") (eq $result "http") (eq $result "https")) -}}
{{- fail ".Values.readinessCheck.asiNodes.scheme is not valid. Valid values are HTTP or HTTPS" -}}
{{- end -}}

{{- $result := .Values.readinessCheck.apiNode.path -}}
{{- if not ( eq $result "/propertyUI/app") -}}
	{{- fail "Provide a valid value for Values.readinessCheck.apiNode.path. Applicable value is /propertyUI/app " -}}
{{- end -}}

{{- $result := .Values.readinessCheck.apiNode.scheme -}}
{{- if not (or (eq $result "HTTP") (eq $result "HTTPS") (eq $result "http") (eq $result "https")) -}}
{{- fail ".Values.readinessCheck.apiNode.scheme is not valid. Valid values are HTTP or HTTPS" -}}
{{- end -}}
*/}}

{{- $isValid := .Values.persistence.enabled | toString -}}
{{- if not ( or (eq $isValid "false") (eq $isValid "true")) -}}
{{- fail "Please provide value for field Values.persistence.enabled. Value can be either true or false." -}}
{{- end -}}

{{- $dynamicProvisioning := .Values.persistence.useDynamicProvisioning | toString -}}
{{- if not ( or (eq $dynamicProvisioning "false") (eq $dynamicProvisioning "true")) -}}
{{- fail "Please provide value for field Values.persistence.useDynamicProvisioning. Value can be either true or false." -}}
{{- end -}}

{{- $resourcesPVCEnabled := .Values.appResourcesPVC.enabled | toString -}}
{{- if eq $resourcesPVCEnabled "true" -}}

{{- if (.Values.appResourcesPVC.preDefinedResourcePVCName) }}
{{- $resourceexist := (empty (lookup "v1" "PersistentVolumeClaim" .Release.Namespace .Values.appResourcesPVC.preDefinedResourcePVCName)) | ternary "false" "true"  }}
{{ if (eq $resourceexist "false") }}
{{- fail "Error: PVC .Values.appResourcesPVC.preDefinedResourcePVCName not found in namespace.." -}}
{{- end -}}
{{- end -}}

{{- $accessMode := .Values.appResourcesPVC.accessMode -}}
{{- if not ( or (eq $accessMode "ReadWriteOnce") (eq $accessMode "ReadWriteOncePod") (eq $accessMode "ReadOnlyMany") (eq $accessMode "ReadWriteMany") ( not (empty .Values.appResourcesPVC.preDefinedResourcePVCName))) -}}
{{- fail "Please specify Values.appResourcesPVC.accessMode as one of these supported access mode - ReadWriteOnce | ReadOnlyMany | ReadWriteMany | ReadWriteOncePod" -}}
{{- end -}}

{{- end -}}

{{- $consoleLogsEnabled := .Values.logs.enableAppLogOnConsole | toString -}}
{{- if eq $consoleLogsEnabled "false" -}}
{{- if (.Values.appLogsPVC.preDefinedLogsPVCName) }}
{{- $resourceexist := (empty (lookup "v1" "PersistentVolumeClaim" .Release.Namespace .Values.appLogsPVC.preDefinedLogsPVCName)) | ternary "false" "true"  }}
{{ if (eq $resourceexist "false") }}
{{- fail "Error: PVC .Values.appLogsPVC.preDefinedLogsPVCName not found in namespace.." -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- $documentsPVCEnabled := .Values.appDocumentsPVC.enabled | toString -}}
{{- if eq $documentsPVCEnabled "true" -}}
{{- $isValid := .Values.appDocumentsPVC.enableVolumeClaimPerPod | toString -}}
{{- if not ( or (eq $isValid "false") (eq $isValid "true")) -}}
{{- fail "Please provide a valid value for .Values.appDocumentsPVC.enableVolumeClaimPerPod. Value can be either true or false." -}}
{{- end -}}
{{- if .Values.appDocumentsPVC.enableVolumeClaimPerPod }}
{{- $accessMode := .Values.appDocumentsPVC.accessMode -}}
{{- if not ( or (eq $accessMode "ReadWriteOnce") (eq $accessMode "ReadWriteOncePod")) -}}
{{- fail "The supported values for Values.appDocumentsPVC.accessMode are only ReadWriteOnce or ReadWriteOncePod when .Values.appDocumentsPVC.enableVolumeClaimPerPod is enabled" -}}
{{- end -}}
{{- end -}}

{{- if (.Values.appDocumentsPVC.preDefinedDocumentPVCName) }}
{{- $resourceexist := (empty (lookup "v1" "PersistentVolumeClaim" .Release.Namespace .Values.appDocumentsPVC.preDefinedDocumentPVCName)) | ternary "false" "true"  }}
{{ if (eq $resourceexist "false") }}
{{- fail "Error: PVC .Values.appDocumentsPVC.preDefinedDocumentPVCName not found in namespace.." -}}
{{- end -}}
{{- if (.Values.appDocumentsPVC.enableVolumeClaimPerPod) -}}
{{- fail "Configuration for .Values.appDocumentsPVC.preDefinedDocumentPVCName is not applicable when .Values.appDocumentsPVC.enableVolumeClaimPerPod is enabled." -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- $accessMode := .Values.appLogsPVC.accessMode -}}
{{- if not ( or (eq $accessMode "ReadWriteOnce") (eq $accessMode "ReadWriteOncePod") (eq $accessMode "ReadOnlyMany") (eq $accessMode "ReadWriteMany") ( not (empty .Values.appResourcesPVC.preDefinedLogsPVCName))) -}}
{{- fail "Please specify Values.appLogsPVC.accessMode as one of these supported access modes - ReadWriteOnce | ReadOnlyMany | ReadWriteMany | ReadWriteOncePod" -}}
{{- end -}}
		
{{- if .Values.security.supplementalGroups -}}
    {{- range .Values.security.supplementalGroups }}
    	{{- $isValid := include "userOrGroupNameIDValidator" . -}}
		{{- if eq $isValid "false" -}}
		{{- fail "Values.security.supplementalGroups is invalid. Either provide a numeric value for group ID or follow the pattern ^[a-z][-a-z0-9]*$ to provide valid group name in an array." -}}
		{{- end -}}
    {{- end }}
{{- end -}}

{{- if .Values.security.fsGroup -}}
{{- $isValid := include "userOrGroupNameIDValidator" .Values.security.fsGroup -}}
{{- if eq $isValid "false" -}}
{{- fail "Values.security.fsGroup is invalid. Either provide a numeric value for group ID or follow the pattern ^[a-z][-a-z0-9]*$ to provide valid group name." -}}
{{- end }}
{{- end -}}

{{- if .Values.security.fsGroupChangePolicy -}}
{{- $fsGroupChangePolicy := .Values.security.fsGroupChangePolicy -}}
{{- if not ( or (eq $fsGroupChangePolicy "OnRootMismatch") (eq $fsGroupChangePolicy "Always") ) -}}
{{- fail "Please specify valid value for Values.security.fsGroupChangePolicy. Value can be OnRootMismatch | Always" -}}
{{- end }}
{{- end -}}

{{- if .Values.security.runAsUser -}}
{{- $isValid := include "userOrGroupNameIDValidator" .Values.security.runAsUser -}}
{{- if eq $isValid "false" -}}
{{- fail "Values.security.runAsUser is invalid. Either provide a numeric value for user ID or follow the pattern ^[a-z][-a-z0-9]*$ to provide valid user name." -}}
{{- end }}
{{- end -}}

{{- if .Values.security.runAsGroup -}}
{{- $isValid := include "userOrGroupNameIDValidator" .Values.security.runAsGroup -}}
{{- if eq $isValid "false" -}}
{{- fail "Values.security.runAsGroup is invalid. Either provide a numeric value for group ID or follow the pattern ^[a-z][-a-z0-9]*$ to provide valid group name." -}}
{{- end }}
{{- end -}}

{{- $isValid := .Values.global.license | toString -}}
{{- if not (eq $isValid "true") -}}
{{- fail "Please accept the license by setting Values.global.license to true. License agreements and information can be viewed by clicking the license specified in values.yaml" -}}
{{- end -}}

{{- $isValid := .Values.env.upgradeCompatibilityVerified -}}
{{- if not ( or (eq $isValid false) (eq $isValid true)) -}}
{{- fail "Please provide value for Values.env.upgradeCompatibilityVerified. Value can be either true or false." -}}
{{- end -}}

{{- $isValid := .Values.ingress.enabled | toString -}}
{{- if not ( or (eq $isValid "false") (eq $isValid "true")) -}}
{{- fail "Please provide value for Values.ingress.enabled. Value can be either false or true." -}}
{{- end -}}
{{- $isValid := .Values.ingress.enabled | toString -}}
{{- if eq $isValid "true" -}}
	{{- $result := include "mandatoryArgumentsCheck" .Values.asi.ingress.internal.host -}}
	{{- if eq $result "false" -}}
	{{- fail ".Values.asi.ingress.internal.host cannot be empty" -}}
	{{- end -}}

	{{- $noOfAPIReplica := .Values.api.replicaCount | int -}}
    {{- if gt $noOfAPIReplica 0 -}}
		{{- $result := include "mandatoryArgumentsCheck" .Values.api.ingress.internal.host -}}
		{{- if eq $result "false" -}}
		{{- fail ".Values.api.ingress.internal.host cannot be empty" -}}
		{{- end -}}
    {{- end -}}
{{- end -}}

{{- $isValid := .Values.asi.autoscaling.enabled | toString -}}
{{- if not ( or (eq $isValid "false") (eq $isValid "true")) -}}
{{- fail "Please provide value for Values.asi.autoscaling.enabled. Value can be either false or true." -}}
{{- end -}}

{{- $isValid := .Values.asi.autoscaling.enabled | toString -}}
{{- if eq $isValid "true" -}}
	{{- $isValid := include "integerValidation" .Values.asi.autoscaling.minReplicas -}}
	{{- if eq $isValid "false" -}}
	{{- fail "Values.asi.autoscaling.minReplicas is not valid." -}}
	{{- end -}}

	{{- $isValid := include "integerValidation" .Values.asi.autoscaling.maxReplicas -}}
	{{- if eq $isValid "false" -}}
	{{- fail "Values.asi.autoscaling.maxReplicas is not valid." -}}
	{{- end -}}

	{{- $isValid := include "integerValidation" .Values.asi.autoscaling.targetCPUUtilizationPercentage -}}
	{{- if eq $isValid "false" -}}
	{{- fail "Values.asi.autoscaling.targetCPUUtilizationPercentage is not valid." -}}
	{{- end -}}
{{- end -}}


{{- $isValid := .Values.ac.autoscaling.enabled | toString -}}
{{- if not ( or (eq $isValid "false") (eq $isValid "true")) -}}
{{- fail "Please provide value for  Values.ac.autoscaling.enabled. Value can be either false or true." -}}
{{- end -}}

{{- $isValid := .Values.ac.autoscaling.enabled | toString -}}
{{- if eq $isValid "true" -}}
	{{- $isValid := include "integerValidation" .Values.ac.autoscaling.minReplicas -}}
	{{- if eq $isValid "false" -}}
	{{- fail "Values.autoscaling.ac.minReplicas is not valid." -}}
	{{- end -}}

	{{- $isValid := include "integerValidation" .Values.ac.autoscaling.maxReplicas -}}
	{{- if eq $isValid "false" -}}
	{{- fail "Values.ac.autoscaling.maxReplicas is not valid." -}}
	{{- end -}}

	{{- $isValid := include "integerValidation" .Values.ac.autoscaling.targetCPUUtilizationPercentage -}}
	{{- if eq $isValid "false" -}}
	{{- fail "Values.ac.autoscaling.targetCPUUtilizationPercentage is not valid." -}}
	{{- end -}}
{{- end -}}

{{- $isValid := .Values.api.autoscaling.enabled | toString -}}
{{- if not ( or (eq $isValid "false") (eq $isValid "true")) -}}
{{- fail "Please provide value for Values.api.autoscaling.enabled. Value can be either false or true." -}}
{{- end -}}

{{- $isValid := .Values.api.autoscaling.enabled | toString -}}
{{- if eq $isValid "true" -}}
	{{- $isValid := include "integerValidation" .Values.api.autoscaling.minReplicas -}}
	{{- if eq $isValid "false" -}}
	{{- fail "Values.api.autoscaling.minReplicas is not valid." -}}
	{{- end -}}

	{{- $isValid := include "integerValidation" .Values.api.autoscaling.maxReplicas -}}
	{{- if eq $isValid "false" -}}
	{{- fail "Values.api.autoscaling.maxReplicas is not valid." -}}
	{{- end -}}

	{{- $isValid := include "integerValidation" .Values.api.autoscaling.targetCPUUtilizationPercentage -}}
	{{- if eq $isValid "false" -}}
	{{- fail "Values.api.autoscaling.targetCPUUtilizationPercentage is not valid." -}}
	{{- end -}}
{{- end -}}

{{- $enableAppLogOnConsole := .Values.logs.enableAppLogOnConsole | toString -}}
{{- if not ( or (eq $enableAppLogOnConsole "false") (eq $enableAppLogOnConsole "true")) -}}
{{- fail "Please provide correct value for Values.logs.enableAppLogOnConsole. Value can be either false or true." -}}
{{- end -}}	

{{- $applyPolicyToKubeSystem := .Values.applyPolicyToKubeSystem | toString -}}
{{- if not ( or (eq $applyPolicyToKubeSystem "false") (eq $applyPolicyToKubeSystem "true")) -}}
{{- fail "Please provide value for applyPolicyToKubeSystem. Value can be either false or true." -}}
{{- end -}}

{{/*
Starting Validation of setup configuration properties.
*/}}

{{- $isValid := .Values.setupCfg.licenseAcceptEnableSfg | toString -}}
{{- if not ( or (eq $isValid "false") (eq $isValid "true")) -}}
{{- fail "Please provide value for Values.setupCfg.licenseAcceptEnableSfg. Value can be either false or true." -}}
{{- end -}}

{{- $isValid := .Values.setupCfg.licenseAcceptEnableEbics | toString -}}
{{- if not ( or (eq $isValid "false") (eq $isValid "true")) -}}
{{- fail "Please provide value for Values.setupCfg.licenseAcceptEnableEbics. Value can be either false or true." -}}
{{- end -}}

{{- $isValid := .Values.setupCfg.licenseAcceptEnableFinancialServices | toString -}}
{{- if not ( or (eq $isValid "false") (eq $isValid "true")) -}}
{{- fail "Please provide value for Values.setupCfg.licenseAcceptEnableFinancialServices. Value can either be false or true." -}}
{{- end -}}

{{- $result := include "mandatoryArgumentsCheck" .Values.setupCfg.systemPassphraseSecret -}}
{{- if eq $result "false" -}}
{{- fail ".Values.setupCfg.systemPassphraseSecret cannot be empty" -}}
{{- end -}}

{{- $isValid := .Values.setupCfg.enableFipsMode | toString -}}
{{- if not ( or (eq $isValid "false") (eq $isValid "true")) -}}
{{- fail "Please provide value for Values.setupCfg.enableFipsMode. Value can be either false or true." -}}
{{- end -}}

{{- $isValid := .Values.setupCfg.nistComplianceMode | toString -}}
{{- if not (or (eq $isValid "strict") (eq $isValid "transition") (eq $isValid "off")) -}}
{{- fail "Invalid value for nistComplianceMode. Valid values are strict,transition or off" -}}
{{- end -}}

{{- $isValid := .Values.setupCfg.dbVendor -}}
{{- if not ( or (eq $isValid "DB2") (eq $isValid "Oracle") (eq $isValid "MSSQL") (eq $isValid "db2") (eq $isValid "oracle") (eq $isValid "mssql")) -}}
{{- fail "Please specify dbVendor as one of these supported databases - DB2 | Oracle | MSSQL" -}}
{{- end -}}

{{- $result := include "mandatoryArgumentsCheck" .Values.setupCfg.dbSecret -}}
{{- if eq $result "false" -}}
{{- fail ".Values.setupCfg.dbSecret cannot be empty" -}}
{{- end -}}

{{- $isValid := include "mandatoryArgumentsCheck" .Values.setupCfg.dbHost -}}
{{- if eq $isValid "false" -}}
{{- fail "Please specify the dbHost." -}}
{{- end -}}

{{- $isValid := include "isPortValid" .Values.setupCfg.dbPort -}}
{{- if eq $isValid "false" -}}
{{- fail "Please specify the dbPort correctly." -}}
{{- end -}}

{{- $isValid := include "mandatoryArgumentsCheck" .Values.setupCfg.dbData -}}
{{- if eq $isValid "false" -}}
{{- fail "Please specify the dbData." -}}
{{- end -}}

{{- $isValid := .Values.setupCfg.dbCreateSchema | toString -}}
{{- if not ( or (eq $isValid "false") (eq $isValid "true")) -}}
{{- fail "Please provide Value for dbCreateSchema. Value can be either false or true." -}}
{{- end -}}

{{- $isValid := .Values.setupCfg.oracleUseServiceName | toString -}}
{{- if not ( or (eq $isValid "false") (eq $isValid "true")) -}}
{{- fail "Please provide Value for oracleUseServiceName. Value can be either false or true." -}}
{{- end -}}

{{- $isValid := .Values.setupCfg.usessl | toString -}}
{{- if not ( or (eq $isValid "false") (eq $isValid "true")) -}}
{{- fail "Please provide Value for usessl. Value can be either false or true." -}}
{{- end -}}

{{- $isSSL := .Values.setupCfg.usessl | toString -}}
{{- $dbVendor := .Values.setupCfg.dbVendor -}}
{{- if and (eq $isSSL "true") ( or (eq $dbVendor "oracle") (eq $dbVendor "Oracle")) -}}
	{{- if not .Values.setupCfg.dbTruststore -}}
	{{- fail "Please provide the path of dbTruststore file." -}}
        {{- end -}}
	{{- if not .Values.setupCfg.dbKeystore -}}
        {{- fail "Please provide the path of dbKeystore file." -}}
        {{- end -}}
{{- end -}}

{{- $isValid := include "mandatoryArgumentsCheck" .Values.setupCfg.adminEmailAddress -}}
{{- if eq $isValid "false" -}}
{{- fail "Please specify the adminEmailAddress." -}}
{{- end -}}

{{- $isValid := include "emailValidator" .Values.setupCfg.adminEmailAddress -}}
{{- if eq $isValid "false" -}}
{{- fail "Please specify a valid adminEmailAddress." -}}
{{- end -}}

{{- $isValid := include "mandatoryArgumentsCheck" .Values.setupCfg.smtpHost -}}
{{- if eq $isValid "false" -}}
{{- fail "Please specify the smtpHost." -}}
{{- end -}}

{{- if .Values.setupCfg.terminationGracePeriod -}}
	{{- $isValid := include "integerValidation" .Values.setupCfg.terminationGracePeriod -}}
	{{- if eq $isValid "false" -}}
	{{- fail "Invalid value for terminationGracePeriod" -}}
	{{- end -}}
{{- end -}}

{{- if .Values.setupCfg.jmsVendor -}}
	
	{{- $queueVendor := .Values.setupCfg.jmsVendor -}}
	{{- $isValid := include "mandatoryArgumentsCheck" .Values.setupCfg.jmsConnectionFactory -}}
	{{- if eq $isValid "false" -}}
	{{- fail "Please provide a value for jmsConnectionFactory." -}}
	{{- end -}}

	{{- $isValid := include "mandatoryArgumentsCheck" .Values.setupCfg.jmsQueueName -}}
	{{- if eq $isValid "false" -}}
	{{- fail "Please provide a value for  jmsQueueName." -}}
	{{- end -}}

	{{- if not .Values.setupCfg.jmsConnectionNameList -}}

		{{- $isValid := include "mandatoryArgumentsCheck" .Values.setupCfg.jmsHost -}}
		{{- if eq $isValid "false" -}}
		{{- fail "Please provide a valid value for jmsHost." -}}
		{{- end -}}

		{{- $isValid := include "isPortValid" .Values.setupCfg.jmsPort -}}
		{{- if eq $isValid "false" -}}
		{{- fail "Please provide a valid value for  jmsPort." -}}
		{{- end -}}
        {{- else if not (eq $queueVendor "IBMMQ") -}}
		{{- $connectionNameListRegex := "^[a-zA-Z0-9_\\.\\-]{1,}:[0-9]{1,5}(,[a-zA-Z0-9_\\.\\-]{1,}:[0-9]{1,5})*$" -}}
		{{- $isValid := regexMatch $connectionNameListRegex .Values.setupCfg.jmsConnectionNameList -}}
		{{- if eq $isValid false -}}
        	{{- fail "Invalid jmsConnectionNameList format. Please specify comma separated list of FQDN:PORT" -}}
		{{- end -}}
		
	{{- end -}}

	{{- $isSSLEnabled := .Values.setupCfg.jmsEnableSsl | toString -}}
	{{- if not ( or (eq $isSSLEnabled "false") (eq $isSSLEnabled "true")) -}}
	{{- fail "Please provide Value for jmsEnableSsl. Value can be either false or true." -}}
	{{- end -}}

	{{- if eq $isSSLEnabled "true" -}}

		{{- $isValid := include "mandatoryArgumentsCheck" .Values.setupCfg.jmsTruststorePath -}}
		{{- if eq $isValid "false" -}}
		{{- fail "Please provide a value for jmsTruststorePath." -}}
		{{- end -}}
	{{- end -}}

	{{- if eq $queueVendor "IBMMQ" -}}
		{{- $isValid := include "mandatoryArgumentsCheck" .Values.setupCfg.jmsChannel -}}
		{{- if eq $isValid "false" -}}
		{{- fail "Please provide a value for jmsChannel." -}}
		{{- end -}}
	{{- end -}}

	{{- if and (eq $isSSLEnabled "true") ( or (eq $queueVendor "IBMMQ") (eq $queueVendor "ibmmq")) -}}
		{{- $isValid := include "mandatoryArgumentsCheck" .Values.setupCfg.jmsCiphersuite -}}
		{{- if eq $isValid "false" -}}
		{{- fail "Please provide a value for jmsCiphersuite." -}}
		{{- end -}}

		{{- $isValid := include "mandatoryArgumentsCheck" .Values.setupCfg.jmsProtocol -}}
		{{- if eq $isValid "false" -}}
		{{- fail "Please provide a value for jmsProtocol." -}}
		{{- end -}}

	{{- end -}}

    {{- if eq $isSSLEnabled "false" -}}
        {{- $result := include "mandatoryArgumentsCheck" .Values.setupCfg.jmsSecret -}}
        {{- if eq $result "false" -}}
        {{- fail "Please provide a value for jmsSecret." -}}
        {{- end -}}
	{{- end -}}

{{- end -}}


{{- if .Values.setupCfg.defaultDocumentStorageType -}}
{{- $defaultDocStorageType := (.Values.setupCfg.defaultDocumentStorageType | default "DB") }}
{{- if not ( or (eq $defaultDocStorageType "DB") (eq $defaultDocStorageType "FS") ) -}}
{{- fail "Provide a valid value for .Values.setupCfg.defaultDocumentStorageType from one of these options - DB | FS" -}}
{{- end -}}
{{- end -}}

{{- $isValid := .Values.setupCfg.restartCluster | toString -}}
{{- if not ( or (eq $isValid "false") (eq $isValid "true")) -}}
{{- fail "Please provide value for Values.setupCfg.restartCluster. Value can be either false or true." -}}
{{- end -}}

{{- $isValid := .Values.setupCfg.useSslForRmi | toString -}}
{{- if not ( or (eq $isValid "false") (eq $isValid "true")) -}}
{{- fail "Please provide value for Values.setupCfg.useSslForRmi. Value can be either false or true." -}}
{{- end -}}

{{- if .Values.setupCfg.sapSncSecretName -}}

	{{- $result := include "mandatoryArgumentsCheck" .Values.setupCfg.sapSncLibVendorName -}}
	{{- if eq $result "false" -}}
	{{- fail ".Values.setupCfg.sapSncLibVendorName cannot be empty when sapSncSecretName is configured." -}}
	{{- end -}}

	{{- $result := include "mandatoryArgumentsCheck" .Values.setupCfg.sapSncLibVersion -}}
	{{- if eq $result "false" -}}
	{{- fail ".Values.setupCfg.sapSncLibVersion cannot be empty when sapSncSecretName is configured." -}}
	{{- end -}}

	{{- $result := include "mandatoryArgumentsCheck" .Values.setupCfg.sapSncLibName -}}
	{{- if eq $result "false" -}}
	{{- fail ".Values.setupCfg.sapSncLibName cannot be empty when sapSncSecretName is configured." -}}
	{{- end -}}
{{- end -}}

{{- $isValid := .Values.purge.enabled | toString -}}
{{- if not ( or (eq $isValid "false") (eq $isValid "true")) -}}
{{- fail "Please provide value for Values.purge.enabled. Value can be either false or true." -}}
{{- end -}}

{{- $purgeEnabled := .Values.purge.enabled | toString -}}
{{- if eq $purgeEnabled "true" -}}

	{{- $result := include "mandatoryArgumentsCheck" .Values.purge.image.repository -}}
	{{- if eq $result "false" -}}
	{{- fail ".Values.purge.image.repository cannot be empty." -}}
	{{- end -}}
	
	{{- if not .Values.purge.image.digest -}}
	{{- $result := include "mandatoryArgumentsCheck" .Values.purge.image.tag -}}
	{{- if eq $result "false" -}}
	{{- fail "Please specify either .Values.purge.image.tag or .Values.purge.image.digest" -}}
	{{- end -}}
	{{- end -}}
	
	{{- $result := include "mandatoryArgumentsCheck" .Values.purge.image.pullPolicy -}}
	{{- if eq $result "false" -}}
	{{- fail ".Values.purge.image.pullPolicy cannot be empty" -}}
	{{- end -}}
	
	{{- $isValid := include "mandatoryArgumentsCheck" .Values.purge.schedule -}}
	{{- if eq $isValid "false" -}}
	{{- fail "Please specify the purge schedule." -}}
	{{- end -}}
	
	{{- if .Values.purge.startingDeadlineSeconds -}}
		{{- $result := include "integerValidation" .Values.purge.startingDeadlineSeconds -}}
		{{- if eq $result "false" -}}
		{{- fail "Provide a valid value for .Values.purge.startingDeadlineSeconds" -}}
		{{- end -}}
	{{- end -}}
	
	{{- if .Values.purge.activeDeadlineSeconds -}}
		{{- $result := include "integerValidation" .Values.purge.activeDeadlineSeconds -}}
		{{- if eq $result "false" -}}
		{{- fail "Provide a valid value for .Values.purge.activeDeadlineSeconds" -}}
		{{- end -}}
	{{- end -}}
	
	{{- $isValid := .Values.purge.suspend | toString -}}
	{{- if not ( or (eq $isValid "false") (eq $isValid "true")) -}}
	{{- fail "Please provide value for Values.purge.suspend. Value can be either false or true." -}}
	{{- end -}}
	
	{{- if .Values.purge.successfulJobsHistoryLimit -}}
		{{- $result := include "integerValidation" .Values.purge.successfulJobsHistoryLimit -}}
		{{- if eq $result "false" -}}
		{{- fail "Provide a valid value for .Values.purge.successfulJobsHistoryLimit" -}}
		{{- end -}}
	{{- end -}}
	
	{{- if .Values.purge.failedJobsHistoryLimit -}}
		{{- $result := include "integerValidation" .Values.purge.failedJobsHistoryLimit -}}
		{{- if eq $result "false" -}}
		{{- fail "Provide a valid value for .Values.purge.failedJobsHistoryLimit" -}}
		{{- end -}}
	{{- end -}}
	
	{{- if .Values.purge.concurrencyPolicy -}}
		{{- $result := .Values.purge.concurrencyPolicy -}}
		{{- if not (or (eq $result "Forbid") (eq $result "Replace")) -}}
		{{- fail ".Values.purge.concurrencyPolicy is not valid. Valid values are Forbid or Replace" -}}
		{{- end -}}
	{{- end -}}

{{- end -}}

{{ if .Values.asi.externalAccess.port }}
	{{- $result := include "isPortValid" .Values.asi.externalAccess.port -}}
	{{- if eq $result "false" -}}
	{{- fail "Values.asi.externalAccess.port field is not valid." -}}
	{{- end -}}
{{- end }}
{{ if .Values.api.externalAccess.port }}
	{{- $result := include "isPortValid" .Values.api.externalAccess.port -}}
	{{- if eq $result "false" -}}
	{{- fail "Values.api.externalAccess.port field is not valid." -}}
	{{- end -}}
{{- end }}
{{ if and (.Values.asi.internalAccess.enableHttps) (.Values.asi.internalAccess.httpsPort) }}
	{{- $result := include "isPortValid" .Values.asi.internalAccess.httpsPort -}}
	{{- if eq $result "false" -}}
	{{- fail "Values.asi.internalAccess.httpsPort field is not valid." -}}
	{{- end -}}
{{- end }}

{{/*
{{ if .Values.apiGateway.port }}
	{{- $result := include "isPortValid" .Values.apiGateway.port -}}
	{{- if eq $result "false" -}}
	{{- fail "Values.apiGateway.port field is not valid." -}}
	{{- end -}}
{{- end }}

{{ if .Values.apiGateway.protocol }}
	{{- $result := .Values.apiGateway.protocol -}}
	{{- if not (or (eq $result "http") (eq $result "https")) -}}
	{{- fail "Values.apiGateway.protocol is not valid. Valid values are http or https" -}}
	{{- end -}}
{{- end }}
*/}}

{{- if .Values.asi.myFgAccess.myFgPort -}}
	{{- $result := include "isPortValid" .Values.asi.myFgAccess.myFgPort -}}
	{{- if eq $result "false" -}}
	{{- fail "Values.asi.myFgAccess.myFgPort field is not valid." -}}
	{{- end -}}
{{- end -}}

{{- if .Values.asi.myFgAccess.myFgProtocol -}}
	{{- $result := .Values.asi.myFgAccess.myFgProtocol -}}
	{{- if not (or (eq $result "http") (eq $result "https")) -}}
	{{- fail "Values.asi.myFgAccess.myFgProtocol is not valid. Valid values are http or https" -}}
	{{- end -}}
{{- end -}}

{{- if .Values.ac.myFgAccess.myFgPort -}}
	{{- $result := include "isPortValid" .Values.ac.myFgAccess.myFgPort -}}
	{{- if eq $result "false" -}}
	{{- fail "Values.ac.myFgAccess.myFgPort field is not valid." -}}
	{{- end -}}
{{- end -}}

{{- if .Values.ac.myFgAccess.myFgProtocol -}}
	{{- $result := .Values.ac.myFgAccess.myFgProtocol -}}
	{{- if not (or (eq $result "http") (eq $result "https")) -}}
	{{- fail "Values.ac.myFgAccess.myFgProtocol is not valid. Valid values are http or https" -}}
	{{- end -}}
{{- end -}}


{{- if .Values.env.debugMode -}}
{{- $isValid := .Values.env.debugMode | toString -}}
{{- if not ( or (eq $isValid "false") (eq $isValid "true")) -}}
{{- fail "Please provide valid value for .Values.env.debugMode. Value can be either false or true." -}}
{{- end -}}
{{- end -}}

{{/*
boolList 	- Contains the parameter to be checked for boolean flags
skipList 	- Contains the parameter to be be skipped
floatList 	- Contains the parameter to be be checked for float number
*/}}

{{- $boolList := list "IS_DEDUCT_MEM_SAPADAPTER" "ENABLE_HEAP_DUMP_OOM_CONTAINER" "ENABLE_HEAP_DUMP_SGQTCRTLBRK_CONTAINER" "ENABLE_VERBOSE_GC_CONTAINER" "IS_DEDUCT_MEM_BI" "IS_DEDUCT_MEM_CLADAPTER" "ENABLE_HEAP_DUMP_OOM" "ENABLE_HEAP_DUMP_SGQTCRTLBRK" "ENABLE_VERBOSE_GC" "USE_SHADOW_CACHE" "PURGE.PURGE_DOCS_ON_DISK" }}
{{- $skipList := list "JVM_ARGS_SUFFIX_CONTAINER" "JVM_ARGS_PREFIX_CONTAINER" "JVM_ARGS_SUFFIX" "JVM_ARGS_PREFIX" }}
{{- $floatList := list "PROCESSORS" }}

{{/*
Starting the validations around performanceTuning sections for asi and ac 
*/}}

{{- if .Values.asi.performanceTuning.allocateMemToSAP -}}
{{- $isValid := .Values.asi.performanceTuning.allocateMemToSAP | toString -}}
{{- if not ( or (eq $isValid "false") (eq $isValid "true")) -}}
{{- fail "Please provide value for .Values.asi.performanceTuning.allocateMemToSAP. Value can be either false or true." -}}
{{- end -}}
{{- end -}}

{{- if .Values.asi.performanceTuning.allocateMemToCLA -}}
{{- $isValid := .Values.asi.performanceTuning.allocateMemToCLA | toString -}}
{{- if not ( or (eq $isValid "false") (eq $isValid "true")) -}}
{{- fail "Please provide value for .Values.asi.performanceTuning.allocateMemToCLA. Value can be either false or true." -}}
{{- end -}}
{{- end -}}

{{- if .Values.asi.performanceTuning.allocateMemToBI -}}
{{- $isValid := .Values.asi.performanceTuning.allocateMemToBI | toString -}}
{{- if not ( or (eq $isValid "false") (eq $isValid "true")) -}}
{{- fail "Please provide value for .Values.asi.performanceTuning.allocateMemToBI. Value can be either false or true." -}}
{{- end -}}
{{- end -}}

{{- if .Values.asi.performanceTuning.threadsPerCore -}}
{{- $threadsPerCore := .Values.asi.performanceTuning.threadsPerCore | toString }}
{{- if not ( $threadsPerCore | regexMatch "^[0-9]{1,}$" ) -}}
{{- fail "Provide a valid postive integer value for .Values.asi.performanceTuning.threadsPerCore" -}}
{{- end -}}
{{- end -}}

{{- if .Values.asi.performanceTuning.override }}  
	{{- range .Values.asi.performanceTuning.override }}
	{{- $tuningProperty := split "=" . }}
	{{- $key := $tuningProperty._0 | toString }}
	{{- $value := $tuningProperty._1 | toString }}
		{{- if has $key $floatList }}
			{{- if ( not ( $value | regexMatch "^$|^([0-9]*[.])?[0-9]+$" )) }}
				{{- fail "Data validation failed for Values.asi.performanceTuning.override section. Provide a positive numeric value." -}}
			{{- end }}
		{{- else if has $key $boolList }}
			{{- if ( not ( $value | regexMatch "^$|^(?i)(true|false)$" )) }}
				{{- fail "Data validation failed for Values.asi.performanceTuning.override section. Provide a valid boolean value." -}}
			{{- end }}
		{{- else }}
			{{- if and ( not ( has $key $skipList) ) ( not ( $value | regexMatch "^$|^[0-9]{1,}$" )) -}}
				{{- fail "Data validation failed for Values.asi.performanceTuning.override section. Provide a positive integer value." -}}
			{{- end -}}
		{{- end }}
	{{- end }}
{{- end }}

{{- if .Values.ac.performanceTuning.allocateMemToSAP -}}
{{- $isValid := .Values.ac.performanceTuning.allocateMemToSAP | toString -}}
{{- if not ( or (eq $isValid "false") (eq $isValid "true")) -}}
{{- fail "Please provide value for .Values.ac.performanceTuning.allocateMemToSAP. Value can be either false or true." -}}
{{- end -}}
{{- end -}}


{{/*
Starting the data sanity validations for asi-template.properties and ac-template.properties file 
Empty values will be passed.
*/}}

{{- range .Files.Lines "properties/ac-tuning.properties" }}
	{{- if ( . | contains "=") }}
		{{- $tuningProperty := . | split "=" }}
		{{- $key := $tuningProperty._0 }}
		{{- $value := $tuningProperty._1 }}
		{{- if has $key $floatList }}
			{{- if ( not ( $value | regexMatch "^$|^([0-9]*[.])?[0-9]+$" )) }}
				{{- fail "Data validation failed for ac-tuning.properties. Provide a positive numeric value." -}}
			{{- end }}
		{{- else if has $key $boolList }}
			{{- if ( not ( $value | regexMatch "^$|^(?i)(true|false)$" )) }}
				{{- fail "Data validation failed for ac-tuning.properties. Provide a valid boolean value." -}}
			{{- end }}
		{{- else }}
			{{- if and ( not ( has $key $skipList) ) ( not ( $value | regexMatch "^$|^[0-9]{1,}$" )) -}}
				{{- fail "Data validation failed for ac-tuning.properties. Provide a positive integer value." -}}
			{{- end -}}
		{{- end }}
	{{- end }}
{{- end }}

{{- range .Files.Lines "properties/asi-tuning.properties" }}
	{{- if ( . | contains "=") }}
		{{- $tuningProperty := . | split "=" }}
		{{- $key := $tuningProperty._0 }}
		{{- $value := $tuningProperty._1 }}
		{{- if has $key $floatList }}
			{{- if ( not ( $value | regexMatch "^$|^([0-9]*[.])?[0-9]+$" )) }}
				{{- fail "Data validation failed for asi-tuning.properties. Provide a positive numeric value." -}}
			{{- end }}
		{{- else if has $key $boolList }}
			{{- if ( not ( $value | regexMatch "^$|^(?i)(true|false)$" )) }}
				{{- fail "Data validation failed for asi-tuning.properties. Provide a valid boolean value." -}}
			{{- end }}
		{{- else }}
			{{- if and ( not ( has $key $skipList) ) ( not ( $value | regexMatch "^$|^[0-9]{1,}$" )) -}}
				{{- fail "Data validation failed for asi-tuning.properties. Provide a positive integer value." -}}
			{{- end -}}
		{{- end }}
	{{- end }}
{{- end }}

{{- if .Values.setupCfg.libertyKeystoreSecret -}}
	{{- $result := include "mandatoryArgumentsCheck" .Values.setupCfg.libertyKeystoreLocation -}}
	{{- if eq $result "false" -}}
	{{- fail ".Values.setupCfg.libertyKeystoreLocation cannot be empty." -}}
	{{- end -}}
{{- end -}}
	
{{- $isValid := .Values.resourcesInit.enabled | toString -}}
{{- if not ( or (eq $isValid "false") (eq $isValid "true")) -}}
{{- fail "Please provide value for Values.resourcesInit.enabled. Value can be either false or true." -}}
{{- end -}}
{{- if eq $isValid "true" -}}
	{{- $result := .Values.appResourcesPVC.enabled | toString -}}
	{{- if eq $result "true" -}}
	{{- fail "To configure and map application resources either .Values.appResourcesPVC.enabled or .Values.resourcesInit.enabled should be set to true but not both." -}}
	{{- end -}}

	{{- $result := include "mandatoryArgumentsCheck" .Values.resourcesInit.image.repository -}}
	{{- if eq $result "false" -}}
	{{- fail ".Values.resourcesInit.image.repository cannot be empty." -}}
	{{- end -}}

	{{- $result := include "mandatoryArgumentsCheck" .Values.resourcesInit.image.name -}}
	{{- if eq $result "false" -}}
	{{- fail ".Values.resourcesInit.image.name cannot be empty." -}}
	{{- end -}}

	{{- if not .Values.resourcesInit.image.digest -}}
	{{- $result := include "mandatoryArgumentsCheck" .Values.resourcesInit.image.tag -}}
	{{- if eq $result "false" -}}
	{{- fail "Please specify either .Values.resourcesInit.image.tag or .Values.resourcesInit.image.digest " -}}
	{{- end -}}
	{{- end -}}

	{{- $result := include "mandatoryArgumentsCheck" .Values.resourcesInit.image.pullPolicy -}}
	{{- if eq $result "false" -}}
	{{- fail ".Values.resourcesInit.image.pullPolicy cannot be empty." -}}
	{{- end -}}
	
{{- end -}}
	

{{- include "extraPVCvalidation" (list . .Values.extraPVCs .Release.Namespace) -}}
{{- include "extraPVCvalidation" (list . .Values.asi.extraPVCs .Release.Namespace) -}}
{{- include "extraPVCvalidation" (list . .Values.ac.extraPVCs .Release.Namespace) -}}
{{- include "extraPVCvalidation" (list . .Values.api.extraPVCs .Release.Namespace) -}}

{{- $typeStr :=  .Values.global.licenseType | toString | lower -}}
{{- if not ( or (eq $typeStr "prod") (eq $typeStr "non-prod")) -}}
{{- fail "Configuration Error: Please provide a valid value for parameter licenseType. Value can be either prod or non-prod." -}}
{{- end -}}

{{- end -}}
