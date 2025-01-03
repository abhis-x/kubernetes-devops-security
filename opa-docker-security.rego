package main

# Do Not store secrets in ENV variables
secrets_env = [
    "passwd",
    "password",
    "pass",
    "secret",
    "key",
    "access",
    "api_key",
    "apikey",
    "token",
    "tkn"
]

deny[msg] {    
    some i
    input[i].Cmd == "env"
    val := input[i].Value
    secret_found := false
    # Iterate over the secrets_env and check if any secret exists in val
    secret_found = contains_any(val, secrets_env)
    secret_found
    msg = sprintf("Line %d: Potential secret in ENV key found: %s", [i, val])
}

# Helper function to check if any item in secrets_env is in the value
contains_any(val, secrets_env) {
    some j
    contains(lower(val), secrets_env[j])
}

# Only use trusted base images
#deny[msg] {
    #some i
    #input[i].Cmd == "from"
    #val := split(input[i].Value[0], "/")
    #count(val) > 1
    #msg = sprintf("Line %d: use a trusted base image", [i])
#}

# Do not use 'latest' tag for base images
deny[msg] {
    some i
    input[i].Cmd == "from"
    val := split(input[i].Value[0], ":")
    contains(lower(val[1]), "latest")
    msg = sprintf("Line %d: do not use 'latest' tag for base images", [i])
}

# Avoid curl bashing
deny[msg] {
    some i
    input[i].Cmd == "run"
    val := concat(" ", input[i].Value)
    matches := regex.find_n("(curl|wget)[^|^>]*[|>]", lower(val), -1)
    count(matches) > 0
    msg = sprintf("Line %d: Avoid curl bashing", [i])
}

# Do not upgrade your system packages
warn[msg] {
    some i
    input[i].Cmd == "run"
    val := concat(" ", input[i].Value)
    matches := regex.match(".*?(apk|yum|dnf|apt|pip).+?(install|[dist-|check-|group]?up[grade|date]).*", lower(val))
    matches == true
    msg = sprintf("Line: %d: Do not upgrade your system packages: %s", [i, val])
}

# Do not use ADD if possible
deny[msg] {
    some i
    input[i].Cmd == "add"
    msg = sprintf("Line %d: Use COPY instead of ADD", [i])
}

# Any user...
any_user {
    some i
    input[i].Cmd == "user"
}

deny[msg] {
    not any_user
    msg = "Do not run as root, use USER instead"
}

# ... but do not root
forbidden_users = [
    "root",
    "toor",
    "0"
]

deny[msg] {
    some i
    users := [name | some j; input[j].Cmd == "user"; name := input[j].Value]
    lastuser := users[count(users)-1]
    lastuser != ""  # Ensure that there is a valid user before checking
    contains(lower(lastuser), forbidden_users[_])  # Safe iteration on 'forbidden_users'
    msg = sprintf("Line %d: Last USER directive (USER %s) is forbidden", [i, lastuser])
}

# Do not sudo
deny[msg] {
    some i
    input[i].Cmd == "run"
    val := concat(" ", input[i].Value)
    contains(lower(val), "sudo")
    msg = sprintf("Line %d: Do not use 'sudo' command", [i])
}

# Use multi-stage builds
default multi_stage = false
multi_stage = true {
    some i
    input[i].Cmd == "copy"
    val := concat(" ", input[i].Flags)
    contains(lower(val), "--from=")
}
deny[msg] {
    multi_stage == false
    msg = sprintf("You COPY, but do not appear to use multi-stage builds...", [])
}
