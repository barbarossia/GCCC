import { describe, test, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import QuickActions from '../src/components/dashboard/QuickActions';

describe('QuickActions Component', () => {
  test('renders quick actions correctly', () => {
    render(<QuickActions />);

    expect(screen.getByText('快捷操作')).toBeInTheDocument();
    expect(screen.getByText('常用功能入口')).toBeInTheDocument();
  });

  test('displays all default action buttons', () => {
    render(<QuickActions />);

    expect(screen.getByText('参与投票')).toBeInTheDocument();
    expect(screen.getByText('质押挖矿')).toBeInTheDocument();
    expect(screen.getByText('交易市场')).toBeInTheDocument();
    expect(screen.getByText('铸造NFT')).toBeInTheDocument();
    expect(screen.getByText('邀请好友')).toBeInTheDocument();
    expect(screen.getByText('领取奖励')).toBeInTheDocument();
  });

  test('shows action icons', () => {
    render(<QuickActions />);

    // Check for emoji icons
    expect(screen.getByText('🗳️')).toBeInTheDocument(); // Vote
    expect(screen.getByText('🔒')).toBeInTheDocument(); // Stake
    expect(screen.getByText('💹')).toBeInTheDocument(); // Trade
    expect(screen.getByText('🔨')).toBeInTheDocument(); // Mint
    expect(screen.getByText('👥')).toBeInTheDocument(); // Referral
    expect(screen.getByText('🎁')).toBeInTheDocument(); // Claim
  });

  test('displays tip message', () => {
    render(<QuickActions />);

    expect(
      screen.getByText('💡 每日完成任务可获得积分奖励')
    ).toBeInTheDocument();
  });

  test('renders custom actions when provided', () => {
    const customActions = [
      {
        id: 'custom1',
        label: '自定义操作',
        icon: '⚙️',
        color: 'from-red-500 to-blue-500',
      },
      {
        id: 'custom2',
        label: '另一个操作',
        icon: '🎯',
        color: 'from-green-500 to-yellow-500',
      },
    ];

    render(<QuickActions actions={customActions} />);

    expect(screen.getByText('自定义操作')).toBeInTheDocument();
    expect(screen.getByText('另一个操作')).toBeInTheDocument();
    expect(screen.getByText('⚙️')).toBeInTheDocument();
    expect(screen.getByText('🎯')).toBeInTheDocument();
  });

  test('handles disabled actions correctly', () => {
    const actionsWithDisabled = [
      {
        id: 'enabled',
        label: '可用操作',
        icon: '✅',
        color: 'from-green-500 to-blue-500',
      },
      {
        id: 'disabled',
        label: '禁用操作',
        icon: '❌',
        color: 'from-gray-500 to-gray-600',
        disabled: true,
      },
    ];

    render(<QuickActions actions={actionsWithDisabled} />);

    const disabledButton = screen.getByText('禁用操作').closest('button');
    expect(disabledButton).toBeDisabled();
    expect(disabledButton).toHaveClass('opacity-50', 'cursor-not-allowed');
  });
});
