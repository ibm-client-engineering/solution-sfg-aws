{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "ibm-connect-direct.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "ibm-connect-direct.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- $shortname := .Release.Name | trunc 10 -}}
{{- printf "%s-%s" $shortname $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "ibm-connect-direct.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return arch based on kube platform
*/}}
{{- define "ibm-connect-direct.arch" -}}
{{- if (eq "linux/amd64" .Capabilities.KubeVersion.Platform) }}
{{- printf "%s" "amd64" }}
{{- end -}}
{{- end -}}

{{/*
license  parameter must be set to true
*/}}
{{- define "ibm-connect-direct.licenseValidate" -}}
{{ $license := toString .Values.license }}
{{- if eq $license "true"  }}
{{- printf "%s" "true" }}
{{- end -}}
{{- end -}}

