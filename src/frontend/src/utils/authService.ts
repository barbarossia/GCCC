import { User, SignInCredentials, SignUpCredentials, ApiResponse } from '../types';
import { 
  findUserByEmail, 
  findUserByUsername, 
  validatePassword, 
  generateUserId, 
  generateReferralCode,
  addMockUser,
  setMockPassword
} from './mockData';

// Simulate API delay
const delay = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

export const authService = {
  // Sign in function
  signIn: async (credentials: SignInCredentials): Promise<ApiResponse<User>> => {
    await delay(1000); // Simulate network delay

    const { email, password } = credentials;

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return {
        success: false,
        message: '请输入有效的邮箱地址'
      };
    }

    // Find user by email
    const user = findUserByEmail(email);
    if (!user) {
      return {
        success: false,
        message: '用户不存在'
      };
    }

    // Validate password
    if (!validatePassword(email, password)) {
      return {
        success: false,
        message: '密码错误'
      };
    }

    // Update last login time
    user.lastLoginAt = new Date();

    return {
      success: true,
      data: user,
      message: '登录成功'
    };
  },

  // Sign up function
  signUp: async (credentials: SignUpCredentials): Promise<ApiResponse<User>> => {
    await delay(1500); // Simulate network delay

    const { email, username, password, confirmPassword, agreeToTerms } = credentials;

    // Validate required fields
    if (!email || !username || !password || !confirmPassword) {
      return {
        success: false,
        message: '请填写所有必填字段'
      };
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return {
        success: false,
        message: '请输入有效的邮箱地址'
      };
    }

    // Validate username length
    if (username.length < 3 || username.length > 20) {
      return {
        success: false,
        message: '用户名长度必须在3-20个字符之间'
      };
    }

    // Validate username format (alphanumeric and underscore only)
    const usernameRegex = /^[a-zA-Z0-9_]+$/;
    if (!usernameRegex.test(username)) {
      return {
        success: false,
        message: '用户名只能包含字母、数字和下划线'
      };
    }

    // Validate password strength
    if (password.length < 6) {
      return {
        success: false,
        message: '密码长度至少为6个字符'
      };
    }

    // Validate password confirmation
    if (password !== confirmPassword) {
      return {
        success: false,
        message: '两次输入的密码不一致'
      };
    }

    // Check terms agreement
    if (!agreeToTerms) {
      return {
        success: false,
        message: '请同意用户协议和隐私政策'
      };
    }

    // Check if email already exists
    if (findUserByEmail(email)) {
      return {
        success: false,
        message: '该邮箱已被注册'
      };
    }

    // Check if username already exists
    if (findUserByUsername(username)) {
      return {
        success: false,
        message: '该用户名已被使用'
      };
    }

    // Create new user
    const newUser: User = {
      id: generateUserId(),
      email,
      username,
      role: 'user',
      avatar: `https://api.dicebear.com/7.x/avataaars/svg?seed=${username}`,
      level: 1,
      experience: 0,
      kycStatus: 'pending',
      referralCode: generateReferralCode(username),
      totalReferrals: 0,
      activeReferrals: 0,
      createdAt: new Date(),
      updatedAt: new Date()
    };

    // Add user to mock data
    addMockUser(newUser);
    setMockPassword(email, password);

    return {
      success: true,
      data: newUser,
      message: '注册成功'
    };
  },

  // Validate session (for auto-login)
  validateSession: async (token: string): Promise<ApiResponse<User>> => {
    await delay(500);

    // In a real app, validate JWT token
    // For mock, we'll decode the user ID from localStorage
    try {
      const userData = JSON.parse(atob(token));
      const user = findUserByEmail(userData.email);
      
      if (user) {
        return {
          success: true,
          data: user,
          message: '会话有效'
        };
      }
    } catch (error) {
      // Invalid token format
    }

    return {
      success: false,
      message: '会话已过期，请重新登录'
    };
  }
};

// Local storage helpers
export const tokenManager = {
  setToken: (user: User) => {
    const token = btoa(JSON.stringify({ email: user.email, id: user.id }));
    localStorage.setItem('gccc_token', token);
  },

  getToken: (): string | null => {
    return localStorage.getItem('gccc_token');
  },

  removeToken: () => {
    localStorage.removeItem('gccc_token');
  }
};
