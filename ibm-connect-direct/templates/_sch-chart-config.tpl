{{- /*
Chart specific config file for SCH (Shared Configurable Helpers)
_sch-chart-config.tpl is a config file for the chart to specify additional
values and/or override values defined in the sch/_config.tpl file.

*/ -}}

{{- /*
"sch.chart.config.values" contains the chart specific values used to override or provide
additional configuration values used by the Shared Configurable Helpers.
*/ -}}
{{- define "ibm-connect-direct.sch.chart.config.values" -}}
sch:
  chart:
    appName: "ibm-connect-direct"
    metering:
    {{- if eq (toString .Values.licenseType | lower) "non-prod"  }}
      productName: "IBM Sterling Connect Direct Premium Ed Non Prod Certified Container"
      productID: "54f9be5388f94bd4a7fc1c56ca59a6bd"
    {{- else }}
      productName: "IBM Sterling Connect Direct Premium Ed Certified Container"
      productID: "0e99fe73c7ae4b799e11d00a9bbf0db0"
    {{- end }}
      productVersion: "6.2"
      productMetric: "VIRTUAL_PROCESSOR_CORE"
      productChargedContainers: "All"
    podSecurityContext:
      runAsNonRoot: true
      supplementalGroups: 
{{- if .Values.storageSecurity.supplementalGroups }}
{{ toYaml .Values.storageSecurity.supplementalGroups | indent 8 }}
{{- else }}
      - 5555
{{- end }}
      fsGroup: {{ .Values.storageSecurity.fsGroup | default 45678 }}
      runAsUser: {{ .Values.cduser.uid | default 45678 }} 
      runAsGroup:  {{ .Values.cduser.gid | default 45678 }}
    containerSecurityContext:
      privileged: false
      runAsUser: {{ .Values.cduser.uid }}
      readOnlyRootFilesystem: false
      allowPrivilegeEscalation: true
      capabilities:
        drop: [ "ALL" ]
        add: [ "CHOWN", "SETGID", "SETUID", "DAC_OVERRIDE", "FOWNER", "AUDIT_WRITE", "SYS_CHROOT" ]
{{- end -}}
