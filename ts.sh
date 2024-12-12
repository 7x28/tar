#!/bin/bash

# 出力ファイル名を設定
output_file="trusted_advisor_cost_report_$(date +%Y%m%d).csv"

# コスト最適化のチェックIDを取得
echo "Trusted Advisorのチェック一覧を取得中..."
cost_check_id=$(aws support describe-trusted-advisor-checks \
    --language ja \
    --query 'checks[?category==`cost_optimizing`].id | [0]' \
    --output text)

if [ -z "${cost_check_id}" ]; then
    echo "エラー: コスト最適化のチェックIDを取得できませんでした。"
    exit 1
fi

echo "コスト最適化のチェックID: ${cost_check_id}"

# CSVヘッダーを作成
echo "取得日時,月額料金節約の可能性,推奨されるアクション,調査が推奨されるアクション,正常,除外" > "${output_file}"

# Trusted Advisorのチェック結果を取得
echo "チェック結果を取得中..."
check_result=$(aws support describe-trusted-advisor-check-result \
    --check-id "${cost_check_id}" \
    --language ja \
    --query 'result' \
    --output json)

if [ -z "${check_result}" ]; then
    echo "エラー: チェック結果を取得できませんでした。"
    exit 1
fi

# データを抽出
estimated_savings=$(echo "${check_result}" | jq -r '.estimatedMonthlySavings // 0')
recommended_items=$(echo "${check_result}" | jq -r '.categorySpecificSummary.costOptimizing.recommendedItemsCount // 0')
investigation_items=$(echo "${check_result}" | jq -r '.categorySpecificSummary.costOptimizing.reasonCodeSummary.INVESTIGATION_NEEDED // 0')
ok_items=$(echo "${check_result}" | jq -r '.categorySpecificSummary.costOptimizing.reasonCodeSummary.OK // 0')
excluded_items=$(echo "${check_result}" | jq -r '.categorySpecificSummary.costOptimizing.reasonCodeSummary.EXCLUDED // 0')

# 取得した値をチェック（nullの場合は0に置換）
estimated_savings=${estimated_savings:-0}
recommended_items=${recommended_items:-0}
investigation_items=${investigation_items:-0}
ok_items=${ok_items:-0}
excluded_items=${excluded_items:-0}

# 現在の日時を取得
current_datetime=$(date '+%Y-%m-%d %H:%M:%S')

# CSVファイルにデータを追記
echo "${current_datetime},${estimated_savings},${recommended_items},${investigation_items},${ok_items},${excluded_items}" >> "${output_file}"

echo "レポートが ${output_file} に出力されました。"