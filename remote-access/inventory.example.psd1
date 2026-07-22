@{
    SchemaVersion = 1

    Nodes = @{
        laptop = @{
            Account            = 'LAPTOP-NAME\WindowsUser'
            User               = 'WindowsUser'
            TailscaleIPv4      = '100.64.0.10'
            KeyPath            = 'C:\Users\WindowsUser\.ssh\id_ed25519_gpu_remote'
            PublicKey          = 'ssh-ed25519 REPLACE_WITH_LAPTOP_PUBLIC_KEY laptop'
            PublicKeyFingerprint = 'SHA256:5VIrtKUU+Nkzl68aiGgaHxZ1a14eDX5l3Ca+MIrKADY'
            HostKeyFingerprint = 'SHA256:REPLACE_WITH_LAPTOP_HOST_KEY_FINGERPRINT'
        }

        'gpu-5080' = @{
            Account            = 'GPU5080-NAME\WindowsUser'
            User               = 'WindowsUser'
            TailscaleIPv4      = '100.64.0.20'
            KeyPath            = 'C:\Users\WindowsUser\.ssh\id_ed25519_ssh_mesh_gpu_5080'
            PublicKey          = 'ssh-ed25519 REPLACE_WITH_5080_PUBLIC_KEY gpu-5080'
            PublicKeyFingerprint = 'SHA256:REPLACE_WITH_5080_PUBLIC_KEY_FINGERPRINT'
            HostKeyFingerprint = 'SHA256:REPLACE_WITH_5080_HOST_KEY_FINGERPRINT'
        }

        'gpu-5070ti' = @{
            Account            = 'GPU5070TI-NAME\WindowsUser'
            User               = 'WindowsUser'
            TailscaleIPv4      = '100.64.0.30'
            KeyPath            = 'C:\Users\WindowsUser\.ssh\id_ed25519_ssh_mesh_gpu_5070ti'
            PublicKey          = 'ssh-ed25519 REPLACE_WITH_5070TI_PUBLIC_KEY gpu-5070ti'
            PublicKeyFingerprint = 'SHA256:REPLACE_WITH_5070TI_PUBLIC_KEY_FINGERPRINT'
            HostKeyFingerprint = 'SHA256:REPLACE_WITH_5070TI_HOST_KEY_FINGERPRINT'
        }
    }
}
