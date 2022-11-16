output "jenkins_ip" {
  value       = azurerm_public_ip.jenkins
}

resource "local_file" "kube_config" {
    content  = azurerm_kubernetes_cluster.k8s.kube_config_raw
    filename = "kube_config.yaml"
    depends_on = [ azurerm_kubernetes_cluster.k8s]
}

output "tls_private_key" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}