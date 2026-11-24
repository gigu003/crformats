# pkg_user_dir requires one non-empty package name

    Code
      pkg_user_dir(character())
    Condition
      Error:
      ! `package` must be one non-empty package name.

---

    Code
      pkg_user_dir("")
    Condition
      Error:
      ! `package` must be one non-empty package name.

