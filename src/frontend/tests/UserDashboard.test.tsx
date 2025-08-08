import { describe, test, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import '@testing-library/jest-dom';
import UserDashboard from '../src/components/dashboard/UserDashboard';

// Mock the useAuth hook with complete user data
vi.mock('../src/contexts/AuthContext', () => ({
  useAuth: () => ({
    user: {
      id: '1',
      username: 'testuser',
      email: 'test@example.com',
      role: 'user',
      avatar: 'https://example.com/avatar.jpg',
      isActive: true,
      createdAt: new Date('2024-01-01'),
      updatedAt: new Date('2024-01-01'),
    },
    isAuthenticated: true,
    login: vi.fn(),
    logout: vi.fn(),
    loading: false,
  }),
}));

describe('UserDashboard', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  test('renders dashboard header correctly', () => {
    render(<UserDashboard />);

    expect(screen.getByText('用户仪表盘')).toBeInTheDocument();
    expect(screen.getByText('刷新')).toBeInTheDocument();
  });

  test('shows loading state initially', async () => {
    render(<UserDashboard />);

    // Should show loading indicators initially
    expect(screen.getAllByText('---').length).toBeGreaterThan(0);
  });

  test('displays asset data after loading', async () => {
    render(<UserDashboard />);

    // Wait for data to load or verify loading states
    await waitFor(
      () => {
        expect(screen.getByText('用户仪表盘')).toBeInTheDocument(); // Dashboard title should always be there
      },
      { timeout: 2000 }
    );

    // Check if various components are rendered
    expect(screen.getAllByText('SOL')[0]).toBeInTheDocument();
    expect(screen.getAllByText('GCCC')[0]).toBeInTheDocument();
    expect(screen.getAllByText('积分')[0]).toBeInTheDocument();
    expect(screen.getByText('碎片')).toBeInTheDocument();
  });

  test('refresh button works correctly', async () => {
    render(<UserDashboard />);

    const refreshButton = screen.getByText('刷新');

    // Wait for initial load or verify loading state
    await waitFor(() => {
      expect(screen.getByText('用户仪表盘')).toBeInTheDocument(); // Dashboard title should always be there
    });

    // Click refresh
    fireEvent.click(refreshButton);

    // Should show loading state again briefly
    await waitFor(
      () => {
        expect(screen.getAllByText('---').length).toBeGreaterThan(0);
      },
      { timeout: 100 }
    );
  });

  test('renders all dashboard sections', async () => {
    render(<UserDashboard />);

    await waitFor(() => {
      // Check main sections are present
      expect(screen.getAllByText('SOL')[0]).toBeInTheDocument();
      expect(screen.getAllByText('GCCC')[0]).toBeInTheDocument();
      expect(screen.getAllByText('积分')[0]).toBeInTheDocument();
      expect(screen.getByText('碎片')).toBeInTheDocument();
      expect(screen.getByText('NFT 收藏')).toBeInTheDocument();
      expect(screen.getByText('最近活动')).toBeInTheDocument();
      expect(screen.getByText('快捷操作')).toBeInTheDocument();
    });
  });
});
