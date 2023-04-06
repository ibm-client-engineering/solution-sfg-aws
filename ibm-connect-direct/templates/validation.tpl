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
A function to check for validity of service ports
*/}}
{{- define "servicePortsCheck" -}}
{{- $result := include "isPortValid" .port -}}
{{- if eq $result "false" -}}
{{- fail "Provide a valid value for ports in service" -}}
{{- end -}}

{{- $result := include "isPortValid" .targetPort -}}
{{- if eq $result "false" -}}
{{- fail "Provide a valid value for targetPort in service" -}}
{{- end -}}

{{- $result := include "isPortValid" .portRange -}}
{{- if eq $result "false" -}}
{{- fail "Provide a valid value for portRange in service" -}}
{{- end -}}
{{- end -}}

{{/*
A function to validate an email address
*/}}
{{- define "emailValidator" -}}
{{- $emailRegex := "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}" -}}
{{- $isValid := regexMatch $emailRegex . -}}
{{- if eq $isValid true -}}
	true
{{- else -}}
	false	
{{- end -}}
{{- end -}}

{{/*
A function to validate size
*/}}
{{- define "size" -}}
{{- $sizeRegex := "[0-9](K|M|G)[i]" -}}
{{- $isValid := regexMatch $sizeRegex . -}}
{{- if eq $isValid true -}}
        true
{{- else -}}
        false
{{- end -}}
{{- end -}}

{{/*
Main function to test the input validations
*/}}

{{- define "validateInput" -}}
{{- $isValid := toString .Values.license -}}
{{- if ne $isValid "true" -}}
{{- fail "Configuration Error: Please provide a valid value for field Values.license. Set this field as true to accept the license agreement for this chart." -}}
{{- end -}}

{{- $result := include "mandatoryArgumentsCheck" .Values.image.repository -}}
{{- if eq $result "false" -}}
{{- fail "Configuration Missing: .Values.image.repository cannot be empty. Please provide a valid repository name along with image name" -}}
{{- end -}}

{{- $result := include "mandatoryArgumentsCheck" .Values.image.tag -}}
{{- if eq $result "false" -}}
{{- fail "Configuration Missing: .Values.image.tag cannot be empty. Please provide a valid image tag." -}}
{{- end -}}

{{- $result := include "mandatoryArgumentsCheck" .Values.image.pullPolicy -}}
{{- if eq $result "false" -}}
{{- fail "Configuration Missing: .Values.pullPolicy cannot be empty. Please provide a valid pull policy for image." -}}
{{- end -}}

{{/*- $result := include "mandatoryArgumentsCheck" .Values.image.imageSecrets -}}
{{- if eq $result "false" -}}
{{- fail "Configuration Missing: .Values.imageSecrets cannot be empty. Please provide a valid image pull secret" -}}
{{- end -*/}}

{{- $result := include "mandatoryArgumentsCheck" .Values.cdArgs.crtName -}}
{{- if eq $result "false" -}}
{{- fail "Configuration Missing: .Values.cdArgs.crtName cannot be empty. Please provide a valid certificate name needed for Secure+ plus configuration by C:D application" -}}
{{- end -}}

{{- $result := include "mandatoryArgumentsCheck" .Values.cdArgs.configDir -}}
{{- if eq $result "false" -}}
{{- fail "Configuration Missing: .Values.cdArgs.configDir cannot be empty. Please provide a valid configuration directory name created on persistent volume mount path where certificate files are present for Secure+ plsu configuration." -}}
{{- end -}}

{{- $isValid := .Values.persistence.enabled | toString -}}
{{- if not ( or (eq $isValid "false") (eq $isValid "true")) -}}
{{- fail "Configuration Error: Please provide value for field Values.persistence.enabled. Value can be either true or false." -}}
{{- end -}}

{{- $dynamicProvisioning := .Values.persistence.useDynamicProvisioning | toString -}}
{{- if not ( or (eq $dynamicProvisioning "false") (eq $dynamicProvisioning "true")) -}}
{{- fail "Configuration Error: Please provide value for field Values.persistence.useDynamicProvisioning. Value can be either true or false." -}}
{{- end -}}

{{- $isValid := include "size" .Values.pvClaim.size -}}
{{- if eq $isValid "false" -}}
{{- fail "Configuration Error: Please specify Values.pvClaim.size as one of these supported sizes - Ki | Mi | Gi" -}}
{{- end -}}

{{- $result := include "mandatoryArgumentsCheck" .Values.service.type -}}
{{- if eq $result "false" -}}
{{- fail "Configuration Missing: Values.service.type cannot be empty. Please provide a valid service type." -}}
{{- end -}}

{{- $result := .Values.service.type -}}
{{- if not (or (eq $result "NodePort") (eq $result "LoadBalancer") (eq $result "ClusterIP")) -}}
{{- fail "Configuration Error: .Values.service.type is not valid. Valid values are NodePort,LoadBalancer or ClusterIP" -}}
{{- end -}}

{{/*- include "servicePortsCheck" .Values.service -*/}}

{{- $result := include "mandatoryArgumentsCheck" .Values.secret.secretName -}}
{{- if eq $result "false" -}}
{{- fail "Configuration Missing: Please provide valid value for Values.secret.secretName" -}}
{{- end -}}

{{- end -}}

{{/*-  include "validateInput" .  -*/}}

{{- $typeStr :=  .Values.licenseType | toString | lower -}}
{{- if not ( or (eq $typeStr "prod") (eq $typeStr "non-prod")) -}}
{{- fail "Configuration Error: Please provide a valid value for parameter licenseType. Value can be either prod or non-prod." -}}
{{- end -}}
