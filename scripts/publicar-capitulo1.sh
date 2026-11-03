#!/usr/bin/env bash
# Uses GITHUB_TOKEN: its commit does not trigger another workflow/Pages build.
# Explicit Pages rebuild below is required for the existing branch-based site.
set -euo pipefail
: "${SOURCE_SHA:?}" "${BUILD_DIR:?}" "${GITHUB_REPOSITORY:?}" "${GH_TOKEN:?}"
python3 scripts/validar-web.py "$BUILD_DIR"

# Keep the existing Pages source. Never silently switch or replace the site.
gh api "repos/$GITHUB_REPOSITORY/pages" > "$RUNNER_TEMP/pages.json"
python3 - "$RUNNER_TEMP/pages.json" <<'PY'
import json, sys
p = json.load(open(sys.argv[1]))
assert p['build_type'] == 'legacy' and p['source'] == {'branch': 'main', 'path': '/'}, \
    'Expected Pages from main / (root); review Pages settings before publishing.'
PY
site_url=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["html_url"])' "$RUNNER_TEMP/pages.json")
git fetch origin main
if [[ $(git rev-parse origin/main) != "$SOURCE_SHA" ]]; then
  echo '::error::main changed during export. Run Godot Web again on main; stale build was not published.'
  exit 1
fi
git checkout --detach "$SOURCE_SHA"
# Delete obsolete generated assets only. Keep all other site files and this note.
rsync -a --delete --exclude=LEIA-ME.txt "$BUILD_DIR/" capitulo1/
git add -- capitulo1/
if ! git diff --cached --quiet; then
  git config user.name 'github-actions[bot]'
  git config user.email '41898282+github-actions[bot]@users.noreply.github.com'
  git commit -m "build(web): export chapter 1 from ${SOURCE_SHA:0:12} [skip ci]"
  # No force/rebase: a concurrent update fails safely without overwriting it.
  git push origin HEAD:main
fi
published_sha=$(git rev-parse HEAD)
gh api --method POST "repos/$GITHUB_REPOSITORY/pages/builds"
for attempt in $(seq 1 60); do
  gh api "repos/$GITHUB_REPOSITORY/pages/builds/latest" > "$RUNNER_TEMP/pages-build.json"
  status=$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["status"] if d["commit"]==sys.argv[2] else "waiting")' "$RUNNER_TEMP/pages-build.json" "$published_sha")
  if [[ "$status" == built ]]; then
    # Check the public revision too, allowing for the Pages/CDN propagation delay.
    if curl --fail --silent --location --max-time 20 "${site_url%/}/capitulo1/build.json?run=$GITHUB_RUN_ID-$attempt" -o "$RUNNER_TEMP/live-build.json" &&
       python3 -c 'import json,sys; assert json.load(open(sys.argv[1]))["commit"]==sys.argv[2]' "$RUNNER_TEMP/live-build.json" "$SOURCE_SHA"; then
      curl --fail --silent --location --max-time 30 "${site_url%/}/capitulo1/" -o "$RUNNER_TEMP/live-index.html"
      grep -q 'index.js' "$RUNNER_TEMP/live-index.html"
      echo "Published ${site_url%/}/capitulo1/ (source $SOURCE_SHA)" | tee -a "$GITHUB_STEP_SUMMARY"
      exit 0
    fi
  elif [[ "$status" == errored ]]; then
    cat "$RUNNER_TEMP/pages-build.json"
    exit 1
  fi
  sleep 10
done
echo '::error::Pages publication not confirmed. Inspect Pages builds before retrying.'
exit 1
