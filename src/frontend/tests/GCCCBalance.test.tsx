import { describe, test, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import GCCCBalance from '../src/components/dashboard/GCCCBalance';

describe('GCCCBalance Component', () => {
  test('renders GCCC balance correctly', () => {
    render(<GCCCBalance balance={850000} staked={400000} loading={false} />);

    expect(screen.getAllByText('GCCC')[0]).toBeInTheDocument();
    expect(screen.getByText('1,250,000')).toBeInTheDocument(); // total balance + staked
    expect(screen.getByText('850,000')).toBeInTheDocument(); // available balance
    expect(screen.getByText('400,000')).toBeInTheDocument(); // staked amount
  });

  test('shows loading state', () => {
    render(<GCCCBalance balance={0} staked={0} loading={true} />);

    expect(screen.getAllByText('---').length).toBeGreaterThan(0);
  });

  test('displays action buttons', () => {
    render(<GCCCBalance balance={850000} staked={400000} loading={false} />);

    expect(screen.getByText('质押')).toBeInTheDocument();
    expect(screen.getByText('治理')).toBeInTheDocument();
  });

  test('calculates staking ratio correctly', () => {
    render(<GCCCBalance balance={600000} staked={400000} loading={false} />);

    // Staking ratio: 400000 / (600000 + 400000) * 100 = 40%
    expect(screen.getByText('质押比例: 40.0%')).toBeInTheDocument();
  });

  test('shows estimated yield when staked', () => {
    render(<GCCCBalance balance={600000} staked={400000} loading={false} />);

    expect(screen.getByText('预估年收益: ~8% APY')).toBeInTheDocument();
  });

  test('handles zero staking', () => {
    render(<GCCCBalance balance={1000000} staked={0} loading={false} />);

    expect(screen.getAllByText('1,000,000')[0]).toBeInTheDocument(); // total
    expect(screen.getAllByText('1,000,000')[1]).toBeInTheDocument(); // available (same as total)
    expect(screen.getByText('0')).toBeInTheDocument(); // staked

    // Should not show staking ratio and yield when nothing is staked
    expect(screen.queryByText(/质押比例/)).not.toBeInTheDocument();
    expect(screen.queryByText(/预估年收益/)).not.toBeInTheDocument();
  });
});
