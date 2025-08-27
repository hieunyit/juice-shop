package dockerfile.policy

# =========================
#  CẤU HÌNH & BẬT/TẮT RULE
# =========================
# Có thể override bằng data.config.* (conftest -d config/)
# hoặc đặt data.config.skip_rules = {"DF00X", ...} để bỏ qua rule cụ thể.

default deny = []
default warn = []

# Giá trị mặc định (có thể override bằng data.config.*)
cfg := {
  "forbid_latest": true,
  "require_user_nonroot": true,
  "forbid_add": true,
  "check_secret": true,
  "forbid_pipe_install": true,
  "cleanup_pkg_cache": true,

  # Mặc định các rule “không cần thiết” bị TẮT
  "require_pinned_digest": false,
  "require_healthcheck": true,
  "forbid_expose_22": false,
  "allowed_bases": [],   # rỗng = không kiểm allowlist
}

# Hợp nhất config ngoài (nếu có)
config = merged {
  merged := cfg
  some k
  data.config[k]; merged := merged with k as data.config[k]
} else = cfg

skip_rules = s {
  s := data.config.skip_rules
} else = {}

enabled(rule) {
  not skip_rules[rule]
}

# =========
# Helpers
# =========
ins = [i | i := input[_]]
upper(s) = t { t := upper(s) }
lower(s) = t { t := lower(s) }
trim(s) = t { t := trim(s) }

instrs_named(name) = xs {
  xs := [ i | i := ins[_]; upper(i.Instruction) == name ]
}

has_instruction(name) {
  some i
  upper(ins[i].Instruction) == name
}

val(i) = v { v := i.Value }
line(i) = n { n := i.StartLine }

contains_any(s, arr) {
  some n
  contains(lower(s), lower(arr[n]))
}

# =========
# RULES (ID, message)
# =========

# DF001: FROM không dùng :latest (BẬT)
deny[msg] {
  enabled("DF001")
  config.forbid_latest
  i := instrs_named("FROM")[_]
  contains(lower(val(i)), ":latest")
  msg := sprintf("DF001 FROM dùng tag 'latest' (line %d): %s", [line(i), val(i)])
}

# DF002: USER phải non-root (BẬT)
deny[msg] {
  enabled("DF002")
  config.require_user_nonroot
  not has_instruction("USER")
  msg := "DF002 Thiếu USER non-root."
}
deny[msg] {
  enabled("DF002")
  config.require_user_nonroot
  i := instrs_named("USER")[_]
  v := lower(trim(val(i)))
  v == "root" or v == "0"
  msg := sprintf("DF002 USER đang là root (line %d): %s", [line(i), val(i)])
}

# DF003: Cấm ADD, dùng COPY (BẬT)
deny[msg] {
  enabled("DF003")
  config.forbid_add
  i := instrs_named("ADD")[_]
  msg := sprintf("DF003 Tránh dùng ADD (line %d). Hãy dùng COPY.", [line(i)])
}

# DF004: Bắt buộc HEALTHCHECK (BẬT)
deny[msg] {
  enabled("DF004")
  config.require_healthcheck
  not has_instruction("HEALTHCHECK")
  msg := "DF004 Thiếu HEALTHCHECK cho container."
}

# DF005: ENV/ARG không chứa secrets phổ biến (BẬT)
deny[msg] {
  enabled("DF005")
  config.check_secret
  i := instrs_named("ENV")[_]
  s := lower(val(i))
  contains_any(s, ["password", "secret", "token", "aws_access_key_id", "aws_secret_access_key", "apikey"])
  msg := sprintf("DF005 ENV nghi chứa secret (line %d): %s", [line(i), val(i)])
}
deny[msg] {
  enabled("DF005")
  config.check_secret
  i := instrs_named("ARG")[_]
  s := lower(val(i))
  contains(s, "=") and contains_any(s, ["password", "secret", "token", "apikey"])
  msg := sprintf("DF005 ARG có default nghi là secret (line %d): %s", [line(i), val(i)])
}

# DF006: RUN tránh 'curl|bash' / 'wget|sh' (BẬT)
deny[msg] {
  enabled("DF006")
  config.forbid_pipe_install
  i := instrs_named("RUN")[_]
  s := lower(val(i))
  contains(s, "|") and (
    (contains(s, "curl") and (contains(s, "bash") or contains(s, "sh"))) or
    (contains(s, "wget") and (contains(s, "bash") or contains(s, "sh")))
  )
  msg := sprintf("DF006 RUN có pipe install nguy hiểm (line %d): %s", [line(i), val(i)])
}

# DF007: RUN apt/apk install phải dọn cache cùng layer (BẬT)
deny[msg] {
  enabled("DF007")
  config.cleanup_pkg_cache
  i := instrs_named("RUN")[_]
  s := lower(val(i))
  contains(s, "apt-get") and contains(s, "install") and
  not contains_any(s, ["rm -rf /var/lib/apt/lists", "apt-get clean"])
  msg := sprintf("DF007 apt-get install thiếu bước dọn cache (line %d): %s", [line(i), val(i)])
}
deny[msg] {
  enabled("DF007")
  config.cleanup_pkg_cache
  i := instrs_named("RUN")[_]
  s := lower(val(i))
  contains(s, "apk add") and
  not contains_any(s, ["rm -rf /var/cache/apk", "apk cache clean"])
  msg := sprintf("DF007 apk add thiếu bước dọn cache (line %d): %s", [line(i), val(i)])
}

# ----- Các rule tuỳ chọn (TẮT mặc định) -----

# DF008: FROM phải pin @sha256 (TẮT → WARN mặc định để gợi ý)
warn[msg] {
  enabled("DF008")
  not config.require_pinned_digest  # chỉ warn khi không bắt buộc
  i := instrs_named("FROM")[_]
  not contains(val(i), "@sha256:") and not contains(lower(val(i)), "scratch")
  msg := sprintf("DF008 Khuyến nghị pin digest @sha256 cho FROM (line %d): %s", [line(i), val(i)])
}
deny[msg] {
  enabled("DF008")
  config.require_pinned_digest
  i := instrs_named("FROM")[_]
  not contains(val(i), "@sha256:") and not contains(lower(val(i)), "scratch")
  msg := sprintf("DF008 FROM chưa pin digest @sha256 (line %d): %s", [line(i), val(i)])
}

# DF009: Không EXPOSE 22 (TẮT)
warn[msg] {
  enabled("DF009")
  config.forbid_expose_22
  i := instrs_named("EXPOSE")[_]
  contains(lower(val(i)), "22")
  msg := sprintf("DF009 EXPOSE 22 không khuyến nghị (line %d).", [line(i)])
}

# DF010: Allowlist base images (TẮT nếu danh sách rỗng)
deny[msg] {
  enabled("DF010")
  count(config.allowed_bases) > 0
  i := instrs_named("FROM")[_]
  v := lower(val(i))
  not contains_any(v, [b | b := config.allowed_bases[_]])
  msg := sprintf("DF010 Base image không nằm trong allowlist (line %d): %s", [line(i), val(i)])
}
