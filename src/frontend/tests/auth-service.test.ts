import { describe, test, expect, vi } from 'vitest';
import { authService } from '../src/utils/authService';

describe('Auth Service Tests', () => {
  test('should sign in with valid admin credentials', async () => {
    const credentials = {
      email: 'admin@gccc.com',
      password: 'admin123'
    };
    
    const response = await authService.signIn(credentials);
    
    expect(response.success).toBe(true);
    expect(response.data?.email).toBe('admin@gccc.com');
    expect(response.data?.role).toBe('admin');
    expect(response.data?.username).toBe('admin');
  });

  test('should sign in with valid user credentials', async () => {
    const credentials = {
      email: 'user@gccc.com',
      password: 'user123'
    };
    
    const response = await authService.signIn(credentials);
    
    expect(response.success).toBe(true);
    expect(response.data?.email).toBe('user@gccc.com');
    expect(response.data?.role).toBe('user');
    expect(response.data?.username).toBe('normaluser');
  });

  test('should return error for invalid credentials', async () => {
    const credentials = {
      email: 'invalid@test.com',
      password: 'wrongpassword'
    };
    
    const response = await authService.signIn(credentials);
    
    expect(response.success).toBe(false);
    expect(response.message).toBe('用户不存在');
  });

  test('should return error for wrong password', async () => {
    const credentials = {
      email: 'admin@gccc.com',
      password: 'wrongpassword'
    };
    
    const response = await authService.signIn(credentials);
    
    expect(response.success).toBe(false);
    expect(response.message).toBe('密码错误');
  });

  test('should sign up new user successfully', async () => {
    const credentials = {
      email: 'newuser@test.com',
      username: 'newuser',
      password: 'password123',
      confirmPassword: 'password123',
      agreeToTerms: true
    };
    
    const response = await authService.signUp(credentials);
    
    expect(response.success).toBe(true);
    expect(response.data?.email).toBe('newuser@test.com');
    expect(response.data?.username).toBe('newuser');
    expect(response.data?.role).toBe('user');
  });

  test('should return error for existing email during signup', async () => {
    const credentials = {
      email: 'admin@gccc.com',
      username: 'newadmin',
      password: 'password123',
      confirmPassword: 'password123',
      agreeToTerms: true
    };
    
    const response = await authService.signUp(credentials);
    
    expect(response.success).toBe(false);
    expect(response.message).toBe('该邮箱已被注册');
  });

  test('should return error for mismatched passwords', async () => {
    const credentials = {
      email: 'test@example.com',
      username: 'testuser',
      password: 'password123',
      confirmPassword: 'differentpassword',
      agreeToTerms: true
    };
    
    const response = await authService.signUp(credentials);
    
    expect(response.success).toBe(false);
    expect(response.message).toBe('两次输入的密码不一致');
  });
});
