#!/bin/bash
set -e
OUTPUT_DIR="docs/api"
SOURCE_MODULE="ServiceAttach"

echo "📚 DocC 문서 생성 중..."

swift package generate-documentation \
  --target $SOURCE_MODULE \
  --output-path $OUTPUT_DIR \
  --transform-for-static-hosting \
  --hosting-base-path /api \
  --index

echo "✅ 문서가 $OUTPUT_DIR 에 생성되었습니다"
