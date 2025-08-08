export interface User {
  id: string;
  email: string;
  username: string;
  walletAddress?: string;
  role: 'admin' | 'user';
  avatar?: string;
  level: number;
  experience: number;
  kycStatus: 'pending' | 'verified' | 'rejected';
  referralCode: string;
  referredBy?: string;
  totalReferrals: number;
  activeReferrals: number;
  lastLoginAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

export interface SignInCredentials {
  email: string;
  password: string;
}

export interface SignUpCredentials {
  email: string;
  username: string;
  password: string;
  confirmPassword: string;
  agreeToTerms: boolean;
}

export interface AuthContextType {
  user: User | null;
  isLoading: boolean;
  signIn: (credentials: SignInCredentials) => Promise<void>;
  signUp: (credentials: SignUpCredentials) => Promise<void>;
  signOut: () => void;
  isAuthenticated: boolean;
}

export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  message: string;
}
