.PHONY: ci-git-setup ci-git-push gen-csv-if-added setup check assort generate configure-skicka upload

KNOWN_HOSTS := github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
CSV_HEADER := src,subj,tool_type,period,year,content_type,author,image_index,included_pages_num,fix_text
UPLOAD_FROM := ${DOC_DIR}/integrated_pdf
CURRENT_BRANCH := $(shell git symbolic-ref --short HEAD)
UPLOAD_TO_BASE := /過去問管理
UPLOAD_TO_MASTER := $(UPLOAD_TO_BASE)/過去問(複製･再配布禁止)

ci-git-setup:
	@git config --global core.quotepath false \
	&& mkdir -p ~/.ssh && touch ~/.ssh/known_hosts \
	&& echo $(KNOWN_HOSTS) > ~/.ssh/known_hosts \
	&& git config --global user.name "ci-bot" \
	&& git config --global user.email "bot@example.com" \
	&& echo echo gitの設定, Github SSH Keyの追加を行いました

ci-git-push: ci-git-setup
	@if [ ! -n "$$(git status --porcelain)" ]; then \
		echo "変更はありません"; \
		exit 0; \
	fi \
	&& git add . \
	&& git commit -m "[auto] assort $$(git show -s --format=%s)"
	@git tag assorted-$$(git rev-parse HEAD) \
	&& git push origin $$(git rev-parse --abbrev-ref HEAD) --tags

gen-csv-if-added:
	$(eval NEW_CSV_ROWS := $(shell git diff HEAD~ --name-only --diff-filter=A | grep -e pdf -e jpg -e png | sed s/$$/,,,,,,,,,/))
	$(eval NEW_CSV_CONTENT := ${CSV_HEADER}\n${NEW_CSV_ROWS})
	$(eval ADDED_NUM := $(shell echo -n "$(NEW_CSV_ROWS)" | wc -m | sed "s/\ *//"))
	$(eval NEW_CSV_PATH := ../metadatas/unassorted_$(shell git log --date=short --pretty=format:"%ad_%s_%h" -1 | tr "\n" _ | sed 's/[\ \/\n]/_/g').csv)

	$(eval COMMIT_HASH := $(shell git rev-parse HEAD))
	$(eval PARENT_HASHES := $(shell git rev-list --parents -n 1 $(COMMIT_HASH)))
	$(eval PARENT_COUNT := $(shell echo $(PARENT_HASHES) | wc -w))

	@if [[ '${ADDED_NUM}' -eq '0' ]];then echo "追加されたファイルはありません" && exit 0; \
	elif [[ $(PARENT_COUNT) -gt 2 ]];then echo "Merge commitのためCSV生成はスキップされました" && exit 0; fi \
	&& rm -f "${NEW_CSV_PATH}" \
	&& echo -en "${NEW_CSV_CONTENT}" > "${NEW_CSV_PATH}" \
	&& echo "CSVファイル($(NEW_CSV_PATH))が生成されました";

setup:
	poetry install

check:
	@python3 app.py check

assort:
	@python3 app.py assort

is-assortment-completed:
	$(eval BEFORE_SHA1 := $(shell sha1sum /doc/metadatas/* | sha1sum))
	@make assort
	$(eval AFTER_SHA1 := $(shell sha1sum /doc/metadatas/* | sha1sum))

	if [[ ! '$(BEFORE_SHA1)' = '$(AFTER_SHA1)' ]]; then exit 1; fi

generate:
	@rm -rf integrated_pdf
	@python3 app.py generate

configure-skicka:
	@echo '${SKICKA_TOKENCACHE_JSON}' > '/root/.skicka.tokencache.json'

upload: configure-skicka
	# $(eval DIR_PREFIX := $(shell echo ' ($(CURRENT_BRANCH))'))

	$(eval DIR_PREFIX := $(shell if [ "$(CURRENT_BRANCH)" = "master" ]; then \
		echo ''; \
	else \
		echo ' ($(CURRENT_BRANCH))'; \
	fi))

	# アップロードするフォルダの絶対パス
	$(eval UPLOAD_TO := $(shell echo '$(UPLOAD_TO_MASTER)$(DIR_PREFIX)'))
	$(eval UPLOAD_TO_2 := $(shell echo '$(UPLOAD_TO)/2年'))

	skicka mkdir '$(UPLOAD_TO)' || true
	skicka mkdir '$(UPLOAD_TO_2)' || true
	skicka upload -ignore-times '$(UPLOAD_FROM)' '$(UPLOAD_TO_2)'

	$(eval OUTDATED_FILE_PATHS := $(shell \
		skicka -verbose download -ignore-times "$(UPLOAD_TO_2)" "$(UPLOAD_FROM)" 2>&1 | \
		sed "/Downloaded and wrote/!d" | \
		sed -E "s/.*bytes to //"))

	@echo Outdated files:
	@echo '$(OUTDATED_FILE_PATHS)'
	@echo '$(OUTDATED_FILE_PATHS)' | xargs -I{} skicka rm "$(UPLOAD_TO)/{}" || true

	# Temporary setting. FOLLOWING LINES SHOULD BE CHANGED.
	skicka mkdir "$(UPLOAD_TO)/1年" || true
	skicka mkdir "$(UPLOAD_TO)/1年/地理-2019" || true
	mkdir -p "$(UPLOAD_FROM)/地理"
	skicka upload "$(UPLOAD_FROM)/地理" "$(UPLOAD_TO)/1年/地理-2019/"