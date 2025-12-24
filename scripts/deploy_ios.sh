#!/bin/bash
set -e

# 定義顏色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== 開始 iOS 自動化部署流程 ===${NC}"

# 1. 清理與建置
echo -e "${GREEN}[1/3] 清理專案...${NC}"
flutter clean
flutter pub get

echo -e "${GREEN}[2/3] 建置 IPA (Release)...${NC}"
flutter build ipa --release

# 2. 尋找 IPA 檔案
IPA_PATH=$(find build/ios/ipa -name "*.ipa" | head -n 1)

if [ -z "$IPA_PATH" ]; then
    echo -e "${RED}錯誤：找不到 .ipa 檔案。建置可能失敗。${NC}"
    exit 1
fi

echo -e "${GREEN}建置成功！IPA 路徑：${IPA_PATH}${NC}"

# 3. 檢查上傳憑證
echo -e "${YELLOW}=== 準備上傳至 App Store Connect ===${NC}"

if [ -z "$APPLE_ID" ]; then
    read -p "請輸入 Apple ID (Email): " APPLE_ID
fi

if [ -z "$APP_SPECIFIC_PASSWORD" ]; then
    echo -e "${YELLOW}提示：請使用應用程式專用密碼 (App-Specific Password)${NC}"
    echo "若尚未產生，請至 https://appleid.apple.com/account/manage 建立"
    read -s -p "請輸入應用程式專用密碼: " APP_SPECIFIC_PASSWORD
    echo ""
fi

# 4. 上傳
echo -e "${GREEN}[3/3] 正在上傳至 App Store...${NC}"
echo "這可能需要幾分鐘的時間，請稍候..."

xcrun altool --upload-app \
    --type ios \
    --file "$IPA_PATH" \
    --username "$APPLE_ID" \
    --password "$APP_SPECIFIC_PASSWORD"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}=== 上傳成功！ ===${NC}"
    echo "請至 App Store Connect 查看處理進度。"
else
    echo -e "${RED}=== 上傳失敗 ===${NC}"
    echo "請檢查錯誤訊息與憑證是否正確。"
    exit 1
fi
