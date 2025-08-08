// 全局状态管理
const appState = {
    currentUser: null,
    isLoggedIn: false,
    loginStep: 1,
    registerStep: 1,
    selectedWallet: null,
    mockWalletAddress: '9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM'
};

// Mock数据
const mockUser = {
    username: 'CryptoTrader88',
    email: 'trader88@gccc.com',
    walletAddress: '9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM',
    avatar: 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iODAiIGhlaWdodD0iODAiIHZpZXdCb3g9IjAgMCA4MCA4MCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPGNpcmNsZSBjeD0iNDAiIGN5PSI0MCIgcj0iNDAiIGZpbGw9IiMzYjgyZjYiLz4KPHN2ZyB4PSIyMCIgeT0iMjAiIHdpZHRoPSI0MCIgaGVpZ2h0PSI0MCIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJ3aGl0ZSI+CjxwYXRoIGQ9Ik0xMiAyQzEzLjEgMiAxNCAyLjkgMTQgNEMxNCA1LjEgMTMuMSA2IDEyIDZDMTAuOSA2IDEwIDUuMSAxMCA0QzEwIDIuOSAxMC45IDIgMTIgMloiLz4KPHA+WW91IGFyZSBub3QgY29ubmVjdGVkIHRvIGEgd2FsbGV0Ljwv+PC9wYXRoPgo8L3N2Zz4KPC9zdmc+',
    level: 'VIP Diamond',
    vipLevel: 4,
    registrationDate: '2023-01-15',
    kycStatus: 'verified',
    twoFactorEnabled: true,
    totalReferrals: 24,
    activeReferrals: 18,
    referralCode: 'GCCC2024',
    experience: 75,
    maxExperience: 100,
    loginHistory: [
        { device: 'Windows PC', location: 'New York, US', time: '2024-01-15 14:30' },
        { device: 'Mobile App', location: 'Los Angeles, US', time: '2024-01-14 09:15' },
        { device: 'Mac Safari', location: 'Seattle, US', time: '2024-01-13 16:45' }
    ]
};

// DOM元素缓存
const elements = {
    loginBtn: null,
    registerBtn: null,
    loginModal: null,
    registerModal: null,
    profileModal: null,
    welcomePage: null,
    userDashboard: null,
    userMenuBtn: null
};

// 初始化应用
document.addEventListener('DOMContentLoaded', function() {
    initializeElements();
    setupEventListeners();
    updateUI();
});

// 初始化DOM元素引用
function initializeElements() {
    elements.loginBtn = document.getElementById('loginBtn');
    elements.registerBtn = document.getElementById('registerBtn');
    elements.loginModal = document.getElementById('loginModal');
    elements.registerModal = document.getElementById('registerModal');
    elements.profileModal = document.getElementById('profileModal');
    elements.welcomePage = document.getElementById('welcomePage');
    elements.userDashboard = document.getElementById('userDashboard');
    elements.userMenuBtn = document.getElementById('userMenuBtn');
}

// 设置事件监听器
function setupEventListeners() {
    // 导航按钮事件
    if (elements.loginBtn) {
        elements.loginBtn.addEventListener('click', () => openModal('loginModal'));
    }
    
    if (elements.registerBtn) {
        elements.registerBtn.addEventListener('click', () => openModal('registerModal'));
    }

    if (elements.userMenuBtn) {
        elements.userMenuBtn.addEventListener('click', () => openModal('profileModal'));
    }

    // 关闭模态框事件
    document.querySelectorAll('.close-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const modal = e.target.closest('.modal-overlay');
            if (modal) closeModal(modal.id);
        });
    });

    // 模态框背景点击关闭
    document.querySelectorAll('.modal-overlay').forEach(overlay => {
        overlay.addEventListener('click', (e) => {
            if (e.target === overlay) {
                closeModal(overlay.id);
            }
        });
    });

    // 登录相关事件
    setupLoginEvents();
    
    // 注册相关事件
    setupRegisterEvents();
    
    // 个人资料相关事件
    setupProfileEvents();
    
    // 仪表盘事件
    setupDashboardEvents();
}

// 登录事件设置
function setupLoginEvents() {
    // 钱包连接按钮
    document.querySelectorAll('.wallet-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const walletType = e.currentTarget.dataset.wallet;
            connectWallet(walletType);
        });
    });

    // 签名按钮
    const signBtn = document.getElementById('signMessage');
    if (signBtn) {
        signBtn.addEventListener('click', signMessage);
    }

    // 完成登录按钮
    const completeLoginBtn = document.getElementById('completeLogin');
    if (completeLoginBtn) {
        completeLoginBtn.addEventListener('click', completeLogin);
    }

    // 登录模态框内的注册链接
    const loginToRegisterBtn = document.getElementById('loginToRegister');
    if (loginToRegisterBtn) {
        loginToRegisterBtn.addEventListener('click', () => {
            closeModal('loginModal');
            openModal('registerModal');
        });
    }
}

// 注册事件设置
function setupRegisterEvents() {
    // 下一步按钮
    const nextStepBtn = document.getElementById('nextStep');
    if (nextStepBtn) {
        nextStepBtn.addEventListener('click', nextRegisterStep);
    }

    // 返回按钮
    const backStepBtn = document.getElementById('backStep');
    if (backStepBtn) {
        backStepBtn.addEventListener('click', backRegisterStep);
    }

    // 注册按钮
    const registerSubmitBtn = document.getElementById('registerSubmit');
    if (registerSubmitBtn) {
        registerSubmitBtn.addEventListener('click', submitRegistration);
    }

    // 注册模态框内的登录链接
    const registerToLoginBtn = document.getElementById('registerToLogin');
    if (registerToLoginBtn) {
        registerToLoginBtn.addEventListener('click', () => {
            closeModal('registerModal');
            openModal('loginModal');
        });
    }
}

// 个人资料事件设置
function setupProfileEvents() {
    // 标签页切换
    document.querySelectorAll('.tab').forEach(tab => {
        tab.addEventListener('click', (e) => {
            switchTab(e.target.dataset.tab);
        });
    });

    // 保存按钮
    const saveProfileBtn = document.getElementById('saveProfile');
    if (saveProfileBtn) {
        saveProfileBtn.addEventListener('click', saveProfile);
    }

    // 头像上传
    const uploadAvatarBtn = document.getElementById('uploadAvatar');
    if (uploadAvatarBtn) {
        uploadAvatarBtn.addEventListener('click', uploadAvatar);
    }

    // 安全设置切换
    document.querySelectorAll('.security-toggle input').forEach(toggle => {
        toggle.addEventListener('change', (e) => {
            toggleSecuritySetting(e.target.name, e.target.checked);
        });
    });

    // 保存偏好设置
    const savePreferencesBtn = document.getElementById('savePreferences');
    if (savePreferencesBtn) {
        savePreferencesBtn.addEventListener('click', savePreferences);
    }
}

// 仪表盘事件设置
function setupDashboardEvents() {
    // 复制按钮
    document.querySelectorAll('.copy-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const textToCopy = e.target.previousElementSibling.textContent;
            copyToClipboard(textToCopy);
        });
    });

    // 各种操作按钮
    const buttons = {
        editProfile: () => openModal('profileModal'),
        manageWallet: () => showToast('钱包管理功能正在开发中...'),
        securitySettings: () => {
            openModal('profileModal');
            switchTab('security');
        },
        inviteFriends: () => showToast('邀请链接已复制到剪贴板'),
        withdrawRewards: () => showToast('提现功能正在开发中...'),
        viewHistory: () => showToast('历史记录功能正在开发中...')
    };

    Object.keys(buttons).forEach(id => {
        const btn = document.getElementById(id);
        if (btn) {
            btn.addEventListener('click', buttons[id]);
        }
    });
}

// 模态框操作
function openModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.style.display = 'flex';
        document.body.style.overflow = 'hidden';
        
        // 重置状态
        if (modalId === 'loginModal') {
            resetLoginModal();
        } else if (modalId === 'registerModal') {
            resetRegisterModal();
        }
    }
}

function closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.style.display = 'none';
        document.body.style.overflow = 'auto';
    }
}

// 登录流程
function resetLoginModal() {
    appState.loginStep = 1;
    updateLoginStep();
}

function updateLoginStep() {
    // 更新步骤指示器
    document.querySelectorAll('#loginModal .step').forEach((step, index) => {
        step.classList.remove('active', 'completed');
        if (index + 1 === appState.loginStep) {
            step.classList.add('active');
        } else if (index + 1 < appState.loginStep) {
            step.classList.add('completed');
        }
    });

    // 显示对应步骤内容
    document.querySelectorAll('#loginModal .login-step').forEach((step, index) => {
        step.style.display = index + 1 === appState.loginStep ? 'block' : 'none';
    });
}

function connectWallet(walletType) {
    appState.selectedWallet = walletType;
    
    // 模拟连接过程
    showToast(`正在连接 ${walletType} 钱包...`);
    
    setTimeout(() => {
        // 更新钱包地址显示
        const addressElement = document.querySelector('#loginModal .address');
        if (addressElement) {
            addressElement.textContent = appState.mockWalletAddress;
        }
        
        appState.loginStep = 2;
        updateLoginStep();
        showToast(`${walletType} 钱包连接成功！`);
    }, 1500);
}

function signMessage() {
    showToast('正在生成签名消息...');
    
    setTimeout(() => {
        appState.loginStep = 3;
        updateLoginStep();
        showToast('消息签名成功！');
    }, 2000);
}

function completeLogin() {
    showToast('登录成功！欢迎回来！');
    
    setTimeout(() => {
        appState.currentUser = mockUser;
        appState.isLoggedIn = true;
        closeModal('loginModal');
        updateUI();
    }, 1000);
}

// 注册流程
function resetRegisterModal() {
    appState.registerStep = 1;
    updateRegisterStep();
}

function updateRegisterStep() {
    // 更新进度指示器
    document.querySelectorAll('#registerModal .progress-step').forEach((step, index) => {
        step.classList.remove('active');
        if (index + 1 === appState.registerStep) {
            step.classList.add('active');
        }
    });

    // 显示对应步骤内容
    document.querySelectorAll('#registerModal .form-step').forEach((step, index) => {
        step.style.display = index + 1 === appState.registerStep ? 'block' : 'none';
    });

    // 更新按钮状态
    const backBtn = document.getElementById('backStep');
    const nextBtn = document.getElementById('nextStep');
    
    if (backBtn) {
        backBtn.style.display = appState.registerStep === 1 ? 'none' : 'block';
    }
    
    if (nextBtn) {
        nextBtn.style.display = appState.registerStep === 2 ? 'none' : 'block';
    }
}

function nextRegisterStep() {
    if (appState.registerStep < 2) {
        // 简单验证
        const currentForm = document.querySelector(`#registerModal .form-step:nth-child(${appState.registerStep})`);
        const requiredFields = currentForm.querySelectorAll('input[required], select[required]');
        let isValid = true;
        
        requiredFields.forEach(field => {
            if (!field.value.trim()) {
                field.style.borderColor = '#ef4444';
                isValid = false;
            } else {
                field.style.borderColor = '#d1d5db';
            }
        });
        
        if (!isValid) {
            showToast('请填写所有必填字段');
            return;
        }
        
        appState.registerStep++;
        updateRegisterStep();
        
        // 更新钱包确认信息
        if (appState.registerStep === 2) {
            const walletAddressSpan = document.querySelector('#registerModal .wallet-address');
            if (walletAddressSpan) {
                walletAddressSpan.textContent = appState.mockWalletAddress;
            }
        }
    }
}

function backRegisterStep() {
    if (appState.registerStep > 1) {
        appState.registerStep--;
        updateRegisterStep();
    }
}

function submitRegistration() {
    // 检查协议同意
    const termsCheckbox = document.getElementById('agreeTerms');
    const privacyCheckbox = document.getElementById('agreePrivacy');
    
    if (!termsCheckbox.checked || !privacyCheckbox.checked) {
        showToast('请阅读并同意用户协议和隐私政策');
        return;
    }
    
    showToast('正在创建账户...');
    
    setTimeout(() => {
        showToast('注册成功！正在跳转到登录页面...');
        
        setTimeout(() => {
            closeModal('registerModal');
            openModal('loginModal');
        }, 1500);
    }, 2000);
}

// 个人资料管理
function switchTab(tabName) {
    // 更新标签页状态
    document.querySelectorAll('#profileModal .tab').forEach(tab => {
        tab.classList.remove('active');
        if (tab.dataset.tab === tabName) {
            tab.classList.add('active');
        }
    });

    // 显示对应内容
    document.querySelectorAll('#profileModal .tab-content > div').forEach(content => {
        content.style.display = 'none';
    });
    
    const targetContent = document.getElementById(`${tabName}Tab`);
    if (targetContent) {
        targetContent.style.display = 'block';
    }
}

function saveProfile() {
    showToast('个人资料保存成功！');
}

function uploadAvatar() {
    // 模拟文件上传
    showToast('正在上传头像...');
    
    setTimeout(() => {
        showToast('头像上传成功！');
    }, 1500);
}

function toggleSecuritySetting(setting, enabled) {
    showToast(`${enabled ? '启用' : '禁用'}${setting}成功！`);
}

function savePreferences() {
    showToast('偏好设置保存成功！');
}

// UI更新
function updateUI() {
    if (appState.isLoggedIn && appState.currentUser) {
        // 隐藏欢迎页面，显示用户仪表盘
        if (elements.welcomePage) {
            elements.welcomePage.style.display = 'none';
        }
        if (elements.userDashboard) {
            elements.userDashboard.style.display = 'block';
        }
        
        // 更新导航栏
        if (elements.loginBtn) {
            elements.loginBtn.style.display = 'none';
        }
        if (elements.registerBtn) {
            elements.registerBtn.style.display = 'none';
        }
        if (elements.userMenuBtn) {
            elements.userMenuBtn.style.display = 'flex';
            
            // 更新用户信息显示
            const usernameSpan = elements.userMenuBtn.querySelector('.username');
            const avatarImg = elements.userMenuBtn.querySelector('.user-avatar');
            
            if (usernameSpan) {
                usernameSpan.textContent = appState.currentUser.username;
            }
            if (avatarImg) {
                avatarImg.src = appState.currentUser.avatar;
            }
        }
        
        // 更新仪表盘数据
        updateDashboardData();
    } else {
        // 显示欢迎页面，隐藏用户仪表盘
        if (elements.welcomePage) {
            elements.welcomePage.style.display = 'block';
        }
        if (elements.userDashboard) {
            elements.userDashboard.style.display = 'none';
        }
        
        // 更新导航栏
        if (elements.loginBtn) {
            elements.loginBtn.style.display = 'inline-flex';
        }
        if (elements.registerBtn) {
            elements.registerBtn.style.display = 'inline-flex';
        }
        if (elements.userMenuBtn) {
            elements.userMenuBtn.style.display = 'none';
        }
    }
}

function updateDashboardData() {
    if (!appState.currentUser) return;
    
    const user = appState.currentUser;
    
    // 更新用户资料卡片
    const usernameEl = document.querySelector('.user-profile-card .username');
    const emailEl = document.querySelector('.info-item .value');
    const registrationDateEl = document.querySelectorAll('.info-item .value')[1];
    const kycStatusEl = document.querySelectorAll('.info-item .value')[2];
    const referralCodeEl = document.querySelector('.referral-code');
    const progressFillEl = document.querySelector('.progress-fill');
    const progressInfoEl = document.querySelector('.progress-info span:last-child');
    
    if (usernameEl) usernameEl.textContent = user.username;
    if (emailEl) emailEl.textContent = user.email;
    if (registrationDateEl) registrationDateEl.textContent = user.registrationDate;
    if (kycStatusEl) kycStatusEl.textContent = user.kycStatus === 'verified' ? '已认证' : '未认证';
    if (referralCodeEl) referralCodeEl.textContent = user.referralCode;
    if (progressFillEl) progressFillEl.style.width = `${user.experience}%`;
    if (progressInfoEl) progressInfoEl.textContent = `${user.experience}/${user.maxExperience}`;
    
    // 更新钱包信息
    const walletAddressEl = document.querySelector('.wallet-item .wallet-address');
    if (walletAddressEl) {
        walletAddressEl.textContent = user.walletAddress;
    }
    
    // 更新推荐统计
    const totalReferralsEl = document.querySelector('.referral-stats .stat-number:first-child');
    const activeReferralsEl = document.querySelector('.referral-stats .stat-number:last-child');
    const referralCodeInputEl = document.querySelector('.code-container input');
    
    if (totalReferralsEl) totalReferralsEl.textContent = user.totalReferrals;
    if (activeReferralsEl) activeReferralsEl.textContent = user.activeReferrals;
    if (referralCodeInputEl) referralCodeInputEl.value = user.referralCode;
    
    // 更新个人资料模态框
    updateProfileModalData();
}

function updateProfileModalData() {
    if (!appState.currentUser) return;
    
    const user = appState.currentUser;
    
    // 更新基本信息表单
    const profileForm = document.getElementById('profileTab');
    if (profileForm) {
        const usernameInput = profileForm.querySelector('input[placeholder="请输入用户名"]');
        const emailInput = profileForm.querySelector('input[type="email"]');
        const walletDisplay = profileForm.querySelector('.wallet-address-display input');
        
        if (usernameInput) usernameInput.value = user.username;
        if (emailInput) emailInput.value = user.email;
        if (walletDisplay) walletDisplay.value = user.walletAddress;
    }
    
    // 更新登录历史
    const historyContainer = document.querySelector('.login-history');
    if (historyContainer && user.loginHistory) {
        historyContainer.innerHTML = user.loginHistory.map(history => `
            <div class="history-item">
                <div class="device-info">
                    <i>💻</i>
                    <div>
                        <div class="device">${history.device}</div>
                        <div class="location">${history.location}</div>
                    </div>
                </div>
                <div class="login-time">${history.time}</div>
            </div>
        `).join('');
    }
}

// 工具函数
function copyToClipboard(text) {
    navigator.clipboard.writeText(text).then(() => {
        showToast('已复制到剪贴板！');
    }).catch(() => {
        // 降级方案
        const textArea = document.createElement('textarea');
        textArea.value = text;
        document.body.appendChild(textArea);
        textArea.select();
        document.execCommand('copy');
        document.body.removeChild(textArea);
        showToast('已复制到剪贴板！');
    });
}

function showToast(message, duration = 3000) {
    // 移除现有的toast
    const existingToast = document.querySelector('.toast');
    if (existingToast) {
        existingToast.remove();
    }
    
    // 创建新的toast
    const toast = document.createElement('div');
    toast.className = 'toast';
    toast.innerHTML = `
        <div class="toast-content">
            <span>${message}</span>
            <button class="toast-close" onclick="this.parentElement.parentElement.remove()">×</button>
        </div>
    `;
    
    document.body.appendChild(toast);
    
    // 自动移除
    setTimeout(() => {
        if (toast.parentElement) {
            toast.remove();
        }
    }, duration);
}

// 模拟一些延迟加载
function simulateLoading() {
    // 模拟数据加载
    setTimeout(() => {
        updateDashboardData();
    }, 500);
}

// 表单验证
function validateEmail(email) {
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return re.test(email);
}

function validatePassword(password) {
    return password.length >= 6;
}

// 页面加载完成后执行
window.addEventListener('load', () => {
    simulateLoading();
    
    // 添加一些动画效果
    const cards = document.querySelectorAll('.dashboard-card, .feature-card');
    cards.forEach((card, index) => {
        setTimeout(() => {
            card.style.opacity = '1';
            card.style.transform = 'translateY(0)';
        }, index * 100);
    });
});

// 导出到全局作用域（用于HTML中的onclick事件）
window.appActions = {
    openModal,
    closeModal,
    copyToClipboard,
    showToast
};
