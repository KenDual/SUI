// Bundle Sui SDK và Wallet Standard từ npm packages
// Chạy: npx esbuild bundle-sdk.js --bundle --outfile=sdk-bundle.js --platform=browser --external:@mysten/sui.js

import * as SuiSDK from '@mysten/sui.js';
import { getWallets } from '@wallet-standard/core';

// Expose tất cả lên window
window.SuiSDK = SuiSDK;
window.sui = SuiSDK;
window.suijs = SuiSDK;
window.getWallets = getWallets;

console.log('✅ SDK bundle loaded');
export { SuiSDK, getWallets };
