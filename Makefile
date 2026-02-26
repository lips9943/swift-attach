.PHONY: docs help clean test

help:
	@echo "사용 가능한 명령어:"
	@echo "  make docs    - DocC 문서 생성"
	@echo "  make clean   - 빌드 정리"
	@echo "  make test    - 테스트 실행"

docs:
	./scripts/docs/generate.sh

clean:
	swift build --clean

test:
	swift test
