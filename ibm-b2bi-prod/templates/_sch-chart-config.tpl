# (C) Copyright 2019-2022 Syncsort Incorporated. All rights reserved.

{{- /*
Chart specific config file for SCH (Shared Configurable Helpers)
_sch-chart-config.tpl is a config file for the chart to specify additional 
values and/or override values defined in the sch/_config.tpl file.
 
*/ -}}

{{- /*
"sch.chart.config.values" contains the chart specific values used to override or provide
additional configuration values used by the Shared Configurable Helpers.
*/ -}}
{{- define "b2bi.sch.chart.config.values" -}}
sch:
  chart:
    appName: "b2bi"
    components:
      asiServer:
        name: "asi-server"
      acServer:
        name: "ac-server"
      apiServer:
        name: "api-server"
      asiService:
        name: "asi-svc"
      acService:
        name: "ac-svc"
      apiService:
        name: "api-svc"
      asiFrontendService:
        name: "asi-frontend-svc"
      acFrontendService:
        name: "ac-frontend-svc"
      asiBackendService:
        name: "asi-backend-svc"
      acBackendService:
        name: "ac-backend-svc"
      apiFrontendService:
        name: "api-frontend-svc"
      headlessService:
        name: "cluster-svc"
      rmi:
        name: "rmi"
      rmiServer:
        name: "rmi-server"
      configmap:
        name: "config"
      propertyConfigmap:
        name: "config-property"	
      servicesConfigmap:
        name: "config-services"	
      passphraseSecret:
        name: "passphrase-secret"
      dbSecret:
        name: "db-secret"
      jmsSecret:
        name: "jms-secret"
      libertySecret:
        name: "liberty-secret"
      pullSecret:
        name: "pull-secret"
      asiAutoscaler:
        name: "asi-autoscaler"
      acAutoscaler:
        name: "ac-autoscaler"
      apiAutoscaler:
        name: "api-autoscaler"  
      ingress:
        name: "ingress"
      asiInternalRoute:
        name: "asi-internal-route"
      asiExternalRoute:
        name: "asi-external-route"
      acInternalRoute:
        name: "ac-internal-route"
      acExternalRoute:
        name: "ac-external-route"
      apiInternalRoute:
        name: "api-internal-route"
      dbSetup:
        name: "db-setup"
      podSecurityPolicy:
        name: "psp"
      kubePodSecurityPolicy:
        name: "psp-ks"
      clusterRole:
        name: "psp"
      kubeClusterRole:
        name: "psp-ks"
      roleBinding:
        name: "psp"
      kubeRoleBinding:
        name: "psp-ks"
      securityContextConstraints:
        name: "scc"
      securityContextClusterRole:
        name: "scc"
      securityClusterRoleBinding:
        name: "scc"
      asipodDisruptionBudget:
        name: "asipdb"
      apipodDisruptionBudget:
        name: "apipdb"
      acpodDisruptionBudget:
        name: "acpdb"
      cleanupJob:
        name: "post-delete-cleanup-job"
      appResourcesPVC:
        name: {{ .Values.appResourcesPVC.name | default "resources" }}
      appLogsPVC:
        name:  {{ .Values.appLogsPVC.name | default "logs" }}
      appDocumentsPVC:
        name: {{ .Values.appDocumentsPVC.name | default "documents" }}
      ibmDefaultPullSecret:
        name: "ibm-entitlement-key"
      extPurge:
        name: "ext-purge"
      upgradeCleanupJob:
        name: "pre-upgrade-cleanup-job"
      patchIngressJob:
        name: "postinstall-patch-ingress-job"
      tlsSetupJob:
        name: "preinstall-tls-setup-job"
      sap:
        name: sap
      networkPolicies:
        ingressDenyAll: 
          name: "np-ingress-deny-all" 
        ingressAllowNs: 
          name: "np-ingress-allow-ns"
        ingressAllowExt:
          name: "np-ingress-allow-ext"
        egressDenyAll:
          name: "np-egress-deny-all"
        egressAllowNs:
          name: "np-egress-allow-ns"
      servicesIntegration:
        mountPath: /ibm/services   
    config:
      log4jConfig: "-Dlog4j2.configurationFile=/ibm/b2bi/install/properties/cfxgateway_cfxlog_config.xml,/ibm/b2bi/install/properties/log4j.properties,/ibm/b2bi/install/properties/log4j2-isc.config.xml"
      myfgPortName: myfg
    labelType: "prefixed"
    metering:
      {{- if eq (toString .Values.global.licenseType | lower) "non-prod"  }}
      productID: {{ template "b2bi.metering.nonProductId" . }}
      productName: {{ template "b2bi.metering.nonProductName" . }}
      {{- else }}
      productID: {{ template "b2bi.metering.productId" . }}
      productName: {{ template "b2bi.metering.productName" . }}
      {{- end }}
      productVersion: {{ template "b2bi.metering.productVersion" . }}
      productMetric: {{ template "b2bi.metering.productMetric" . }}
    nonMetering:
      nonChargeableProductMetric: "FREE"
    podSecurityContext:
      runAsNonRoot: true
      {{- if ge (.Capabilities.KubeVersion.Minor|int) 24 }}
      seccompProfile:
        type: RuntimeDefault
      {{- end }}
      supplementalGroups: {{ .Values.security.supplementalGroups }}
	  {{- if .Values.security.fsGroup }}
      fsGroup: {{ .Values.security.fsGroup }}
	  {{- end }}
          {{- if .Values.security.fsGroupChangePolicy }}
      fsGroupChangePolicy: {{ .Values.security.fsGroupChangePolicy }}
          {{- end }}
	  {{- if .Values.security.runAsUser }}
      runAsUser: {{ .Values.security.runAsUser }}
	  {{- end }}
	  {{- if .Values.security.runAsGroup }}
      runAsGroup: {{ .Values.security.runAsGroup }}
	  {{- end }}
    podSecurityContextTest:
      runAsNonRoot: true
      {{- if ge (.Capabilities.KubeVersion.Minor|int) 24 }}
      seccompProfile:
        type: RuntimeDefault
      {{- end }}
      supplementalGroups: {{ .Values.security.supplementalGroups }}
          {{- if .Values.security.fsGroup }}
      fsGroup: {{ .Values.security.fsGroup }}
          {{- end }}
          {{- if .Values.security.fsGroupChangePolicy }}
      fsGroupChangePolicy: {{ .Values.security.fsGroupChangePolicy }}
          {{- end }}
    containerSecurityContext:
      privileged: false
      {{- if .Values.security.runAsUser }}
      runAsUser: {{ .Values.security.runAsUser }}
	  {{- end }}
	  {{- if .Values.security.runAsGroup }}
      runAsGroup: {{ .Values.security.runAsGroup }}
	  {{- end }}
      readOnlyRootFilesystem: false
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL     
    containerSecurityContextTest:
      privileged: false
      readOnlyRootFilesystem: false
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
{{- end -}}
