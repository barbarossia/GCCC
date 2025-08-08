import React, { createContext, useContext, useReducer, useEffect, ReactNode } from 'react';
import { User, SignInCredentials, SignUpCredentials, AuthContextType } from '../types';
import { authService, tokenManager } from '../utils/authService';

// Auth state interface
interface AuthState {
  user: User | null;
  isLoading: boolean;
  error: string | null;
}

// Auth actions
type AuthAction =
  | { type: 'SET_LOADING'; payload: boolean }
  | { type: 'SET_USER'; payload: User | null }
  | { type: 'SET_ERROR'; payload: string | null }
  | { type: 'SIGN_OUT' };

// Initial state
const initialState: AuthState = {
  user: null,
  isLoading: true,
  error: null
};

// Auth reducer
const authReducer = (state: AuthState, action: AuthAction): AuthState => {
  switch (action.type) {
    case 'SET_LOADING':
      return {
        ...state,
        isLoading: action.payload
      };
    case 'SET_USER':
      return {
        ...state,
        user: action.payload,
        isLoading: false,
        error: null
      };
    case 'SET_ERROR':
      return {
        ...state,
        error: action.payload,
        isLoading: false
      };
    case 'SIGN_OUT':
      return {
        ...state,
        user: null,
        isLoading: false,
        error: null
      };
    default:
      return state;
  }
};

// Create context
const AuthContext = createContext<AuthContextType | undefined>(undefined);

// Auth provider props
interface AuthProviderProps {
  children: ReactNode;
}

// Auth provider component
export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [state, dispatch] = useReducer(authReducer, initialState);

  // Initialize auth state on app load
  useEffect(() => {
    const initializeAuth = async () => {
      const token = tokenManager.getToken();
      
      if (token) {
        try {
          const response = await authService.validateSession(token);
          if (response.success && response.data) {
            dispatch({ type: 'SET_USER', payload: response.data });
          } else {
            tokenManager.removeToken();
            dispatch({ type: 'SET_USER', payload: null });
          }
        } catch (error) {
          tokenManager.removeToken();
          dispatch({ type: 'SET_USER', payload: null });
        }
      } else {
        dispatch({ type: 'SET_LOADING', payload: false });
      }
    };

    initializeAuth();
  }, []);

  // Sign in function
  const signIn = async (credentials: SignInCredentials): Promise<void> => {
    dispatch({ type: 'SET_LOADING', payload: true });
    dispatch({ type: 'SET_ERROR', payload: null });

    try {
      const response = await authService.signIn(credentials);
      
      if (response.success && response.data) {
        tokenManager.setToken(response.data);
        dispatch({ type: 'SET_USER', payload: response.data });
      } else {
        dispatch({ type: 'SET_ERROR', payload: response.message });
        dispatch({ type: 'SET_LOADING', payload: false });
      }
    } catch (error) {
      dispatch({ type: 'SET_ERROR', payload: '登录失败，请稍后重试' });
      dispatch({ type: 'SET_LOADING', payload: false });
    }
  };

  // Sign up function
  const signUp = async (credentials: SignUpCredentials): Promise<void> => {
    dispatch({ type: 'SET_LOADING', payload: true });
    dispatch({ type: 'SET_ERROR', payload: null });

    try {
      const response = await authService.signUp(credentials);
      
      if (response.success && response.data) {
        tokenManager.setToken(response.data);
        dispatch({ type: 'SET_USER', payload: response.data });
      } else {
        dispatch({ type: 'SET_ERROR', payload: response.message });
        dispatch({ type: 'SET_LOADING', payload: false });
      }
    } catch (error) {
      dispatch({ type: 'SET_ERROR', payload: '注册失败，请稍后重试' });
      dispatch({ type: 'SET_LOADING', payload: false });
    }
  };

  // Sign out function
  const signOut = (): void => {
    tokenManager.removeToken();
    dispatch({ type: 'SIGN_OUT' });
  };

  // Context value
  const value: AuthContextType = {
    user: state.user,
    isLoading: state.isLoading,
    signIn,
    signUp,
    signOut,
    isAuthenticated: !!state.user,
    error: state.error
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};

// Custom hook to use auth context
export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
