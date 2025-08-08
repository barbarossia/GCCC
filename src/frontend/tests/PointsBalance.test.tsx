import { describe, test, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import PointsBalance from '../src/components/dashboard/PointsBalance';

describe('PointsBalance Component', () => {
  test('renders points balance correctly', () => {
    render(
      <PointsBalance
        points={8950}
        level={15}
        nextLevelPoints={10000}
        loading={false}
      />
    );

    expect(screen.getByText('积分')).toBeInTheDocument();
    expect(screen.getByText('8,950')).toBeInTheDocument();
    expect(screen.getByText('Lv.15')).toBeInTheDocument();
  });

  test('shows loading state', () => {
    render(
      <PointsBalance
        points={0}
        level={1}
        nextLevelPoints={1000}
        loading={true}
      />
    );

    expect(screen.getAllByText('---').length).toBeGreaterThan(0);
  });

  test('calculates points needed for next level', () => {
    render(
      <PointsBalance
        points={8950}
        level={15}
        nextLevelPoints={10000}
        loading={false}
      />
    );

    // Next level points needed: 10000 - 8950 = 1050
    expect(screen.getByText('1,050')).toBeInTheDocument();
  });

  test('shows max level state', () => {
    render(
      <PointsBalance
        points={10000}
        level={20}
        nextLevelPoints={10000}
        loading={false}
      />
    );

    expect(screen.getByText('已满级')).toBeInTheDocument();
  });

  test('displays action buttons', () => {
    render(
      <PointsBalance
        points={8950}
        level={15}
        nextLevelPoints={10000}
        loading={false}
      />
    );

    expect(screen.getByText('签到')).toBeInTheDocument();
    expect(screen.getByText('任务')).toBeInTheDocument();
  });

  test('shows point earning methods', () => {
    render(
      <PointsBalance
        points={8950}
        level={15}
        nextLevelPoints={10000}
        loading={false}
      />
    );

    expect(screen.getByText('• 每日签到: +10分')).toBeInTheDocument();
    expect(screen.getByText('• 参与投票: +50分')).toBeInTheDocument();
    expect(screen.getByText('• 推荐用户: +100分')).toBeInTheDocument();
  });

  test('handles progress bar correctly', () => {
    const { container } = render(
      <PointsBalance
        points={5000}
        level={10}
        nextLevelPoints={10000}
        loading={false}
      />
    );

    // Find the progress bar element - just check if it exists
    const progressContainer = container.querySelector(
      '.bg-gradient-to-r.from-blue-500.to-purple-500'
    );
    expect(progressContainer).toBeInTheDocument();

    // Check that it's displayed (not hidden)
    expect(progressContainer).toBeVisible();
  });
});
