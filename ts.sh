#!/bin/bash

# 結果を保存するCSVファイル名
output_file="trusted_advisor_summary_$(date +%Y%m%d).csv"

# CSVヘッダーの作成
echo "CheckName,Category,Status,ResourcesFlagged,EstimatedMonthlySavings" > $output_file

# Trusted Advisorのチェックリスト取得
aws support describe-trusted-advisor-checks --language en | \
jq -r '.checks[] | select(.category != null) | .id + "," + .name' | while IFS=, read -r check_id check_name
do
    # 各チェックの詳細結果を取得
    check_result=$(aws support describe-trusted-advisor-check-result --check-id "$check_id")
    
    # jqを使用して必要な情報を抽出
    category=$(echo $check_result | jq -r '.result.checkName' | cut -d'[' -f1)
    status=$(echo $check_result | jq -r '.result.status')
    resources_flagged=$(echo $check_result | jq -r '.result.resourcesSummary.resourcesFlagged')
    savings=$(echo $check_result | jq -r '.result.categorySpecificSummary.costOptimizing.estimatedMonthlySavings // "N/A"')

    # CSVフォーマットで出力
    echo "\"$check_name\",\"$category\",\"$status\",\"$resources_flagged\",\"$savings\"" >> $output_file
done

echo "レポートが $output_file に生成されました。"