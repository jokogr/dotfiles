[(self: super: {
  pgcli = (super.pgcli.overrideAttrs (oldAttrs: { doCheck = false; }));
})]
