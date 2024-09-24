let
  cfcosta = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO7NVKxM60JPOU8GydRSNuUXDLiQdxA4C1I2VL8B8Iqr"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOVjPDqpK/UP5RzRE3bEcnrwtlH89q6F52zGPiS1+fl0"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINLzY57vvPa2YMFY9LqOyTwfUektkff4FwPauFmD4l6h"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL9QChBH6PiVr7xJxlgnR0GqwJIijq6wkNUPS31ZWpMD"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPsNDYN8h93HAYAqgi4oIgvM0zlfsE7cl/cfPuw68jXm"
  ];
in
{
  "deluge.age".publicKeys = cfcosta;
  "env.sh.age".publicKeys = cfcosta;
  "localhost.crt.age".publicKeys = cfcosta;
  "localhost.key.age".publicKeys = cfcosta;
  "mullvad.age".publicKeys = cfcosta;
  "rootCA-key.pem.age".publicKeys = cfcosta;
}
