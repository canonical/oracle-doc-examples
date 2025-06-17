locals {
  arch_to_shape = {
    "amd64" = "VM.Standard.E4.Flex"
    "arm64" = "VM.Standard.A1.Flex"
  }

  instance_shape = local.arch_to_shape[var.architecture]
}
