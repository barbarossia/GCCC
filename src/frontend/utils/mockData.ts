import { User } from '@/types';

// Mock users data
export const mockUsers: User[] = [
  {
    id: '1',
    email: 'admin@gccc.com',
    username: 'admin',
    walletAddress: '9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM',
    role: 'admin',
    avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=admin',
    level: 10,
    experience: 10000,
    kycStatus: 'verified',
    referralCode: 'ADMIN2024',
    totalReferrals: 100,
    activeReferrals: 85,
    lastLoginAt: new Date('2024-01-15T10:30:00Z'),
    createdAt: new Date('2023-01-01T00:00:00Z'),
    updatedAt: new Date('2024-01-15T10:30:00Z')
  },
  {
    id: '2',
    email: 'user@gccc.com',
    username: 'normaluser',
    walletAddress: 'FhYXQVFJ8kKvVRN7VdtqwXgF3nQhWGtKdLm5YWnPcDnv',
    role: 'user',
    avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=normaluser',
    level: 3,
    experience: 750,
    kycStatus: 'verified',
    referralCode: 'USER2024',
    totalReferrals: 5,
    activeReferrals: 3,
    lastLoginAt: new Date('2024-01-14T15:20:00Z'),
    createdAt: new Date('2023-06-15T00:00:00Z'),
    updatedAt: new Date('2024-01-14T15:20:00Z')
  }
];

// Mock passwords (in real app, these would be hashed)
export const mockPasswords: Record<string, string> = {
  'admin@gccc.com': 'admin123',
  'user@gccc.com': 'user123'
};

// Helper functions
export const findUserByEmail = (email: string): User | undefined => {
  return mockUsers.find(user => user.email === email);
};

export const findUserByUsername = (username: string): User | undefined => {
  return mockUsers.find(user => user.username === username);
};

export const validatePassword = (email: string, password: string): boolean => {
  return mockPasswords[email] === password;
};

export const generateUserId = (): string => {
  return Date.now().toString() + Math.random().toString(36).substr(2, 9);
};

export const generateReferralCode = (username: string): string => {
  return username.toUpperCase() + Math.random().toString(36).substr(2, 4).toUpperCase();
};

// Add new user to mock data
export const addMockUser = (user: User): void => {
  mockUsers.push(user);
};

// Set password for new user
export const setMockPassword = (email: string, password: string): void => {
  mockPasswords[email] = password;
};
