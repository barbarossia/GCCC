import React, { useState } from 'react';
import { useAuth } from '../contexts/AuthContext';

interface LoginFormProps {
  onSwitchToSignUp: () => void;
}

const LoginForm: React.FC<LoginFormProps> = ({ onSwitchToSignUp }) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const { signIn, error, isLoading } = useAuth();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await signIn({ email, password });
    } catch (err) {
      console.error('Login failed:', err);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      <div>
        <label className="block text-sm font-medium text-blue-100 mb-2">
          邮箱地址
        </label>
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className="w-full px-4 py-3 bg-white bg-opacity-20 border border-white border-opacity-30 rounded-lg text-white placeholder-blue-200 input-focus"
          placeholder="请输入邮箱地址"
          required
        />
      </div>

      <div>
        <label className="block text-sm font-medium text-blue-100 mb-2">
          密码
        </label>
        <input
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          className="w-full px-4 py-3 bg-white bg-opacity-20 border border-white border-opacity-30 rounded-lg text-white placeholder-blue-200 input-focus"
          placeholder="请输入密码"
          required
        />
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
            登录中...
          </div>
        ) : (
          '登录'
        )}
      </button>

      <div className="text-center">
        <span className="text-blue-200">还没有账户？</span>
        <button
          type="button"
          onClick={onSwitchToSignUp}
          className="text-blue-300 hover:text-white ml-2 font-medium"
        >
          立即注册
        </button>
      </div>
    </form>
  );
};

export default LoginForm;
