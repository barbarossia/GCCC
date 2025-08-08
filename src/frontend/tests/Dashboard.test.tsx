import { describe, test, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import Dashboard from '../src/components/dashboard/Dashboard';

// Mock the dashboard components
vi.mock('../src/components/dashboard/UserDashboard', () => ({
  default: () => <div data-testid='user-dashboard'>User Dashboard</div>,
}));

vi.mock('../src/components/dashboard/AdminDashboard', () => ({
  default: () => <div data-testid='admin-dashboard'>Admin Dashboard</div>,
}));

// Mock the useAuth hook
vi.mock('../src/contexts/AuthContext', () => ({
  useAuth: vi.fn(),
}));

import { useAuth } from '../src/contexts/AuthContext';

describe('Dashboard Component', () => {
  test('shows loading state when user is null', () => {
    (useAuth as any).mockReturnValue({
      user: null,
      isAuthenticated: false,
    });

    render(<Dashboard />);

    expect(screen.getByText('加载中...')).toBeInTheDocument();
    expect(document.querySelector('.animate-spin')).toBeInTheDocument();
  });

  test('renders UserDashboard for regular user', () => {
    (useAuth as any).mockReturnValue({
      user: {
        id: '1',
        username: 'testuser',
        role: 'user',
      },
      isAuthenticated: true,
    });

    render(<Dashboard />);

    expect(screen.getByTestId('user-dashboard')).toBeInTheDocument();
    expect(screen.queryByTestId('admin-dashboard')).not.toBeInTheDocument();
  });

  test('renders AdminDashboard for admin user', () => {
    (useAuth as any).mockReturnValue({
      user: {
        id: '1',
        username: 'admin',
        role: 'admin',
      },
      isAuthenticated: true,
    });

    render(<Dashboard />);

    expect(screen.getByTestId('admin-dashboard')).toBeInTheDocument();
    expect(screen.queryByTestId('user-dashboard')).not.toBeInTheDocument();
  });

  test('defaults to UserDashboard for unknown role', () => {
    (useAuth as any).mockReturnValue({
      user: {
        id: '1',
        username: 'testuser',
        role: 'unknown',
      },
      isAuthenticated: true,
    });

    render(<Dashboard />);

    expect(screen.getByTestId('user-dashboard')).toBeInTheDocument();
    expect(screen.queryByTestId('admin-dashboard')).not.toBeInTheDocument();
  });
});
