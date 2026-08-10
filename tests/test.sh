#!/bin/sh
set -eu
unset CDPATH

repo_dir=$(cd -- "$(dirname "$0")/.." && pwd)
fixture_bin="$repo_dir/tests/fixtures/bin"
original_path=$PATH
test_root=$(mktemp -d "${TMPDIR:-/tmp}/syncpick-tests.XXXXXX")

cleanup() {
  cleanup_code=$?
  trap - EXIT INT TERM
  find "$test_root" -type f -delete 2>/dev/null || true
  find "$test_root" -depth -type d -exec rmdir {} \; 2>/dev/null || true
  exit "$cleanup_code"
}
trap cleanup EXIT INT TERM

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  haystack=$1
  needle=$2
  printf '%s\n' "$haystack" | grep -F -- "$needle" >/dev/null || fail "expected output to contain: $needle"
}

assert_not_contains() {
  haystack=$1
  needle=$2
  if printf '%s\n' "$haystack" | grep -F -- "$needle" >/dev/null; then
    fail "expected output not to contain: $needle"
  fi
}

assert_file_contains() {
  file=$1
  needle=$2
  grep -F -- "$needle" "$file" >/dev/null || fail "expected $file to contain: $needle"
}

new_case() {
  case_name=$1
  case_root="$test_root/$case_name"
  config_root="$case_root/config"
  state_root="$case_root/state"
  destination_root="$case_root/destination"
  log_root="$case_root/log"
  response_root="$case_root/responses"
  mkdir -p "$config_root/syncpick/profiles" "$state_root" "$destination_root" "$log_root" "$response_root"
  destination_display=$(cd -- "$destination_root" && pwd -P)
  export XDG_CONFIG_HOME="$config_root"
  export XDG_STATE_HOME="$state_root"
  export SYNCPICK_TEST_LOG_DIR="$log_root"
  export SYNCPICK_TEST_RESPONSE_DIR="$response_root"
  export PATH="$fixture_bin:$original_path"
  unset NO_COLOR SYNCPICK_TEST_SSH_OUTPUT_FILE SYNCPICK_TEST_SSH_STATUS SYNCPICK_TEST_SSH_EXECUTE SYNCPICK_TEST_VALIDATE_STATUS SYNCPICK_TEST_RSYNC_STATUS_FILE || true
}

make_profile() {
  profile_id=$1
  display_name=$2
  shift 2
  profile_file="$config_root/syncpick/profiles/$profile_id.conf"
  {
    printf '%s\n' '# Test profile'
    printf 'profile_name="%s"\n' "$display_name"
    printf '%s\n' 'profile_host="fixture-host"'
    printf 'profile_rsync_bin="%s"\n' "$fixture_bin/rsync"
    printf 'profile_ssh_bin="%s"\n' "$fixture_bin/ssh"
    printf '%s\n' \
      'profile_delete="0"' \
      'profile_inplace="0"' \
      'profile_path_highlighting="1"' \
      'profile_queue_path_display="short"' \
      'profile_sources=('
    for source_root in "$@"; do
      printf '  "%s"\n' "$source_root"
    done
    printf '%s\n' ')'
  } > "$profile_file"
  chmod 600 "$profile_file"
}

write_response() {
  key=$1
  shift
  printf '%s\n' "$@" > "$response_root/$key"
}

write_ssh_output() {
  ssh_output_file="$case_root/ssh-output"
  printf '%s\n' "$@" > "$ssh_output_file"
  export SYNCPICK_TEST_SSH_OUTPUT_FILE="$ssh_output_file"
}

test "$(zsh "$repo_dir/syncpick" --version)" = "syncpick 0.2.3"
help_output=$(zsh "$repo_dir/syncpick" --help)
assert_contains "$help_output" '-y, --yes                 Skip the final real-sync confirmation'
assert_contains "$help_output" '--stay                Offer to sync more after a successful run'
zsh "$repo_dir/install" --help >/dev/null

new_case profile_picker
make_profile home-nas 'Home NAS' /srv/media
write_response server 'Home NAS'
write_response folders '/srv/media/Example'
output=$(zsh "$repo_dir/syncpick" --dry-run "$destination_root" 2>&1)
assert_contains "$output" 'Ready to preview'
assert_contains "$output" "Destination:  $destination_display"
assert_contains "$output" 'Previewing folder 1 of 1'
assert_contains "$output" 'Dry run complete'
assert_not_contains "$output" 'Proceed?'
assert_file_contains "$log_root/fzf-server-1.input" 'Home NAS  [home-nas]'
assert_file_contains "$log_root/fzf-server-1.args" '--disabled'
assert_file_contains "$log_root/fzf-server-1.args" '--no-input'
assert_file_contains "$log_root/fzf-server-1.args" ' NORMAL  j/k move  g/G ends  i search  q quit '
assert_file_contains "$log_root/fzf-server-1.args" 'j:down,k:up,g:first,G:last,ctrl-d:half-page-down,ctrl-u:half-page-up,q:abort'
assert_file_contains "$log_root/fzf-server-1.args" 'i:show-input+enable-search+change-border-label( INSERT  type to filter  Esc normal )'
assert_file_contains "$log_root/fzf-server-1.args" '/:clear-query+show-input+enable-search+change-border-label( INSERT  type to filter  Esc normal )'
assert_file_contains "$log_root/fzf-server-1.args" 'esc:hide-input+disable-search+change-border-label( NORMAL  j/k move  g/G ends  i search  q quit )'
assert_file_contains "$log_root/fzf-folders-1.args" 'j/k moves. i or / searches. Esc returns to navigation.'
assert_file_contains "$log_root/fzf-folders-1.args" 'No folders queued.'
assert_file_contains "$log_root/rsync-1.args" '-n'
test "$(cat "$state_root/syncpick/last-profile")" = home-nas

new_case cancelled_profile
make_profile home-nas 'Home NAS' /srv/media
write_response server '__CANCEL__'
output=$(zsh "$repo_dir/syncpick" --dry-run "$destination_root" 2>&1)
test -z "$output" || fail "expected profile cancellation to be silent, got: $output"
test ! -f "$log_root/ssh.count"

new_case first_run
write_response folders '/srv/media/Example'
output=$(printf '%s\n' 'First Server' 'fixture-host' '/srv/media' 'no' | zsh "$repo_dir/syncpick" --dry-run "$destination_root" 2>&1)
assert_contains "$output" 'No sync servers are configured yet.'
assert_contains "$output" "Saved 'First Server' as profile 'first-server'."
assert_contains "$output" 'Dry run complete'
test -f "$config_root/syncpick/profiles/first-server.conf"
test ! -f "$log_root/fzf-server-1.input"

new_case partial_sources
make_profile mixed 'Mixed roots' /srv/media /srv/archive
write_ssh_output \
  '__SYNCPICK_ROOT_OK__	/srv/media' \
  '__SYNCPICK_PATH__	/srv/media/Example' \
  '__SYNCPICK_ROOT_ERROR__	/srv/archive'
write_response folders '/srv/media/Example'
output=$(zsh "$repo_dir/syncpick" --server mixed --dry-run "$destination_root" 2>&1)
assert_contains "$output" 'Loaded 1 of 2 source folders.'
assert_contains "$output" 'Could not read:'
assert_contains "$output" '/srv/archive'
assert_contains "$output" 'Dry run complete'

new_case remote_command
remote_root="$case_root/remote source"
mkdir -p "$remote_root/Example" "$remote_root/Another"
make_profile local-fixture 'Local fixture' "$remote_root"
export SYNCPICK_TEST_SSH_EXECUTE=1
write_response folders "$remote_root/Example"
output=$(zsh "$repo_dir/syncpick" --server local-fixture --dry-run "$destination_root" 2>&1)
assert_contains "$output" "$remote_root/Example"
assert_contains "$output" 'Dry run complete'

new_case empty_source
make_profile empty 'Empty root' /srv/empty
write_ssh_output '__SYNCPICK_ROOT_EMPTY__	/srv/empty'
set +e
output=$(zsh "$repo_dir/syncpick" --server empty --dry-run "$destination_root" 2>&1)
exit_code=$?
set -e
test "$exit_code" -eq 1 || fail "expected empty-root exit 1, got $exit_code"
assert_contains "$output" 'No immediate subfolders were found under:'
assert_contains "$output" "No remote folders are available from this profile's source roots."
test ! -f "$log_root/fzf-folders-1.input"

new_case unexpected_remote_output
make_profile noisy 'Noisy shell' /srv/media
write_ssh_output 'Welcome from a noisy shell'
set +e
output=$(zsh "$repo_dir/syncpick" --server noisy --dry-run "$destination_root" 2>&1)
exit_code=$?
set -e
test "$exit_code" -eq 1 || fail "expected noisy-shell exit 1, got $exit_code"
assert_contains "$output" 'unexpected output while listing folders'

new_case collisions
make_profile duplicates 'Duplicate folders' /srv/one /srv/two
write_ssh_output \
  '__SYNCPICK_ROOT_OK__	/srv/one' \
  '__SYNCPICK_PATH__	/srv/one/Example' \
  '__SYNCPICK_ROOT_OK__	/srv/two' \
  '__SYNCPICK_PATH__	/srv/two/Example'
write_response folders '/srv/one/Example|/srv/two/Example'
set +e
output=$(zsh "$repo_dir/syncpick" --server duplicates --dry-run "$destination_root" 2>&1)
exit_code=$?
set -e
test "$exit_code" -eq 1 || fail "expected collision exit 1, got $exit_code"
assert_contains "$output" 'multiple selections map to the same local folder'
test ! -f "$log_root/rsync.count"

new_case cancelled_selection
make_profile home-nas 'Home NAS' /srv/media
write_response folders '__CANCEL__'
output=$(zsh "$repo_dir/syncpick" --server home-nas --dry-run "$destination_root" 2>&1)
assert_contains "$output" 'No selection.'
test ! -f "$log_root/rsync.count"

new_case confirmation
make_profile home-nas 'Home NAS' /srv/media
write_response folders '/srv/media/Example'
output=$(printf '%s\n' maybe yes | zsh "$repo_dir/syncpick" --server home-nas "$destination_root" 2>&1)
assert_contains "$output" 'Please answer yes or no.'
assert_contains "$output" 'Syncing folder 1 of 1'
assert_contains "$output" 'Sync complete'
assert_not_contains "$(cat "$log_root/rsync-1.args")" '-n'

new_case confirmation_eof
make_profile home-nas 'Home NAS' /srv/media
write_response folders '/srv/media/Example'
output=$(zsh "$repo_dir/syncpick" --server home-nas "$destination_root" </dev/null 2>&1)
assert_contains "$output" 'Cancelled.'
test ! -f "$log_root/rsync.count"

new_case assume_yes
make_profile home-nas 'Home NAS' /srv/media
write_response folders '/srv/media/Example'
output=$(zsh "$repo_dir/syncpick" --server home-nas --yes "$destination_root" 2>&1)
assert_not_contains "$output" 'Proceed?'
assert_contains "$output" 'Sync complete'

new_case multiple_folders
make_profile home-nas 'Home NAS' /srv/media
write_ssh_output \
  '__SYNCPICK_ROOT_OK__	/srv/media' \
  '__SYNCPICK_PATH__	/srv/media/Example' \
  '__SYNCPICK_PATH__	/srv/media/Another'
write_response folders '/srv/media/Example|/srv/media/Another'
output=$(zsh "$repo_dir/syncpick" --server home-nas --yes "$destination_root" 2>&1)
assert_contains "$output" 'Syncing folder 1 of 2'
assert_contains "$output" 'Syncing folder 2 of 2'
assert_contains "$output" 'Folders:      2 of 2'
test "$(cat "$log_root/rsync.count")" -eq 2

new_case dangerous_preview
make_profile home-nas 'Home NAS' /srv/media
write_response folders '/srv/media/Example'
output=$(zsh "$repo_dir/syncpick" --server home-nas --dry-run --delete --inplace "$destination_root" 2>&1)
assert_contains "$output" 'WARNING: deletion is enabled.'
assert_contains "$output" 'WARNING: in-place writes are enabled.'
assert_file_contains "$log_root/rsync-1.args" '--delete-delay'
assert_file_contains "$log_root/rsync-1.args" '--inplace'

new_case retry
make_profile home-nas 'Home NAS' /srv/media
write_response folders '/srv/media/Example'
status_file="$case_root/rsync-status"
printf '%s\n' 23 0 > "$status_file"
export SYNCPICK_TEST_RSYNC_STATUS_FILE="$status_file"
output=$(printf '%s\n' yes yes | zsh "$repo_dir/syncpick" --server home-nas "$destination_root" 2>&1)
assert_contains "$output" 'rsync failed for /srv/media/Example with status 23.'
assert_contains "$output" 'Sync complete'
test "$(cat "$log_root/rsync.count")" -eq 2

new_case failed
make_profile home-nas 'Home NAS' /srv/media
write_response folders '/srv/media/Example'
status_file="$case_root/rsync-status"
printf '%s\n' 23 > "$status_file"
export SYNCPICK_TEST_RSYNC_STATUS_FILE="$status_file"
set +e
output=$(printf '%s\n' yes no | zsh "$repo_dir/syncpick" --server home-nas "$destination_root" 2>&1)
exit_code=$?
set -e
test "$exit_code" -eq 23 || fail "expected rsync exit 23, got $exit_code"
assert_contains "$output" 'Sync incomplete'
assert_contains "$output" 'Completed:    0 of 1'
assert_contains "$output" 'Not started:  0'

new_case stay
make_profile home-nas 'Home NAS' /srv/media
write_response folders '/srv/media/Example' '/srv/media/Example'
write_response complete 'Sync more' 'Exit'
output=$(zsh "$repo_dir/syncpick" --server home-nas --dry-run --stay "$destination_root" 2>&1)
test "$(printf '%s\n' "$output" | grep -c 'Dry run complete')" -eq 2
test "$(cat "$log_root/rsync.count")" -eq 2
test "$(cat "$log_root/ssh.count")" -eq 2

new_case accessibility
make_profile home-nas 'Home NAS' /srv/media
write_response folders '/srv/media/Example'
output=$(NO_COLOR=1 COLUMNS=80 zsh "$repo_dir/syncpick" --server home-nas --dry-run "$destination_root" 2>&1)
assert_file_contains "$log_root/fzf-folders-1.args" '--no-color'
assert_file_contains "$log_root/fzf-folders-1.args" 'right,42%,wrap,hidden,border-left'
escape=$(printf '\033')
if grep -F -- "$escape" "$log_root/fzf-folders-1.input" >/dev/null; then
  fail 'NO_COLOR folder rows contained ANSI escapes'
fi

new_case settings
make_profile home-nas 'Home NAS' /srv/media
write_response settings 'Edit profile' 'Done'
write_response profile 'Home NAS'
write_response profile_settings 'Edit connection' 'Done'
output=$(printf '%s\n' 'Renamed NAS' 'renamed-host' | zsh "$repo_dir/syncpick" --configure 2>&1)
assert_contains "$output" 'Connection updated.'
assert_file_contains "$config_root/syncpick/profiles/home-nas.conf" 'profile_name="Renamed NAS"'
assert_file_contains "$config_root/syncpick/profiles/home-nas.conf" 'profile_host="renamed-host"'
assert_file_contains "$config_root/syncpick/profiles/home-nas.conf" "profile_rsync_bin=\"$fixture_bin/rsync\""

new_case deletion_setting
make_profile home-nas 'Home NAS' /srv/media
write_response settings 'Edit profile' 'Done'
write_response profile 'Home NAS'
write_response profile_settings 'Toggle deletion' 'Done'
output=$(printf '%s\n' yes | zsh "$repo_dir/syncpick" --configure 2>&1)
assert_contains "$output" 'Deletion enabled.'
assert_file_contains "$config_root/syncpick/profiles/home-nas.conf" 'profile_delete="1"'

printf '%s\n' 'tests: OK'
