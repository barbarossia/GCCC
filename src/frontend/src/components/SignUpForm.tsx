import React, { useState } from 'react';
import { useAuth } from '../contexts/AuthContext';

interface SignUpFormProps {
  onSwitchToLogin: () => void;
}

const SignUpForm: React.FC<SignUpFormProps> = ({ onSwitchToLogin }) => {
  const [formData, setFormData] = useState({
    email: '',
    username: '',
    password: '',
    confirmPassword: '',
    agreeToTerms: false
  });
  const { signUp, error, isLoading } = useAuth();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await signUp(formData);
    } catch (err) {
      console.error('Sign up failed:', err);
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value, type, checked } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <label className="block text-sm font-medium text-blue-100 mb-2">
          邮箱地址
        </label>
        <input
          type="email"
          name="email"
          value={formData.email}
          onChange={handleChange}
          className="w-full px-4 py-3 bg-white bg-opacity-20 border border-white border-opacity-30 rounded-lg text-white placeholder-blue-200 input-focus"
          placeholder="请输入邮箱地址"
          required
        />
      </div>

      <div>
        <label className="block text-sm font-medium text-blue-100 mb-2">
          用户名
        </label>
        <input
          type="text"
          name="username"
          value={formData.username}
          onChange={handleChange}
          className="w-full px-4 py-3 bg-white bg-opacity-20 border border-white border-opacity-30 rounded-lg text-white placeholder-blue-200 input-focus"
          placeholder="请输入用户名"
          required
        />
      </div>

      <div>
        <label className="block text-sm font-medium text-blue-100 mb-2">
          密码
        </label>
        <input
          type="password"
          name="password"
          value={formData.password}
          onChange={handleChange}
          className="w-full px-4 py-3 bg-white bg-opacity-20 border border-white border-opacity-30 rounded-lg text-white placeholder-blue-200 input-focus"
          placeholder="请输入密码"
          required
        />
      </div>

      <div>
        <label className="block text-sm font-medium text-blue-100 mb-2">
          确认密码
        </label>
        <input
          type="password"
          name="confirmPassword"
          value={formData.confirmPassword}
          onChange={handleChange}
          className="w-full px-4 py-3 bg-white bg-opacity-20 border border-white border-opacity-30 rounded-lg text-white placeholder-blue-200 input-focus"
          placeholder="请再次输入密码"
          required
        />
      </div>

      <div className="flex items-center">
        <input
          type="checkbox"
          name="agreeToTerms"
          checked={formData.agreeToTerms}
          onChange={handleChange}
          className="mr-2"
          required
        />
        <span className="text-blue-200 text-sm">
          我同意 <span className="text-blue-300">用户协议</span> 和 <span className="text-blue-300">隐私政策</span>
        </span>
      </div>

      {error && (
        <div className="error-message text-red-300 text-sm text-center">
          {error}
        </div>
      )}

      <button
        type="submit"
        disabled={isLoading}
        className="w-full py-3 btn-primary text-white font-medium rounded-lg disabled:opacity-50"
      >
        {isLoading ? (
          <div className="flex items-center justify-center">
            <div className="loading-spinner"></div>
            注册中...
          </div>
        ) : (
          '注册'
        )}
      </button>

      <div className="text-center">
        <span className="text-blue-200">已有账户？</span>
        <button
          type="button"
          onClick={onSwitchToLogin}
          className="text-blue-300 hover:text-white ml-2 font-medium"
        >
          立即登录
        </button>
      </div>
    </form>
  );
};

export default SignUpForm;
