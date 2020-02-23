.PHONY: ci-git-setup gen-csv-if-added

ci-git-setup:
	git config --global core.quotepath false
	mkdir -p ~/.ssh && touch ~/.ssh/known_hosts
	echo "github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==" > ~/.ssh/known_hosts
	git config --global user.name "ci-bot"
	git config --global user.email "bot@example.com"

ci-git-push: ci-git-setup
	if [ ! -n "$(git status --porcelain)" ]; then
		echo "変更はありません"
		exit
	fi

	git add -A .
	git commit -m "[auto] assort $(git show -s --format=%s)"
	git push origin $(git rev-parse --abbrev-ref HEAD)

gen-csv-if-added: ci-git-setup
	NEW_CSV="$(git diff HEAD~ --name-only --diff-filter=A | grep -e pdf -e jpg -e png || echo "")"
	ADDED_NUM=$(echo -n "$NEW_CSV" | wc -m | sed "s/\ *//")

	if [[ $ADDED_NUM -ge 1 ]]; then
		NEW_CSV="$(echo -n "$NEW_CSV" | sed s/$/,,,,,,,,,/)"
		NEW_FILE="metadatas/unassorted_$(git log --date=short --pretty=format:"%ad_%s_%h" -1 | tr "\n" _ | sed 's/[\ \/\n]/_/g').csv"
		touch $NEW_FILE
		echo -en "src,subj,tool_type,period,year,content_type,author,image_index,included_pages_num,fix_text\n$NEW_CSV" > $NEW_FILE
		# echo "$NEW_CSV" >> metadatas/unassorted.csv
	fi

setup:
	poetry install

check:
	python3 app.py check

assort:
	git add -A metadatas
	python3 app.py assort

generate:
	rm -rf integrated_pdf
	python3 app.py generate

commit-assorted:
	git add -A metadatas scanned studies tests
	git commit -m "make assort"

configure-skicka:
	echo ${SKICKA_TOKENCACHE_JSON} > /root/.skicka.tokencache.json

upload: configure-skicka generate
	UPLOAD_FROM="integrated_pdf"
	CURRENT_BRANCH=$(git symbolic-ref --short HEAD)

	# 括弧書きでブランチ名をフォルダの末尾に追加
	DIR_PREFIX=" (${CURRENT_BRANCH})"
	# masterブランチの時は括弧書きはつけない
	if [ "${CURRENT_BRANCH}" = "master" ]; then
		DIR_PREFIX=""
	fi

	# アップロードするフォルダの絶対パス
	UPLOAD_BASE_DIR="/過去問管理/過去問(複製･再配布禁止)${DIR_PREFIX}"
	UPLOAD_DIR="${UPLOAD_BASE_DIR}/2年"
	skicka mkdir "${UPLOAD_BASE_DIR}" || true
	skicka mkdir "${UPLOAD_DIR}" || true
	skicka upload -ignore-times "./${UPLOAD_FROM}" "${UPLOAD_DIR}"

	skicka -verbose download -ignore-times "${UPLOAD_DIR}" "./${UPLOAD_FROM}" 2>&1 | \
	sed "/Downloaded and wrote/!d" | \
	sed -E "s/.*bytes to //" | \
	xargs -I{} skicka rm "${UPLOAD_DIR}/{}" || true
	
	# Temporary setting. FOLLOWING LINES SHOULD BE CHANGED
	skicka mkdir "${UPLOAD_BASE_DIR}/1年" || true
	skicka mkdir "${UPLOAD_BASE_DIR}/1年/地理-2019" || true
	mkdir -p "./${UPLOAD_FROM}/地理"
	skicka upload "./${UPLOAD_FROM}/地理" "${UPLOAD_BASE_DIR}/1年/地理-2019/"

