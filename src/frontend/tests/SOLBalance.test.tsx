import { describe, test, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import SOLBalance from '../src/components/dashboard/SOLBalance';

describe('SOLBalance Component', () => {
  test('renders SOL balance correctly', () => {
    render(<SOLBalance balance={45.23} loading={false} />);

    // Use getAllByText to handle multiple SOL occurrences
    expect(screen.getAllByText('SOL')[0]).toBeInTheDocument();
    expect(screen.getByText('45.2300')).toBeInTheDocument(); // Component formats to 4 decimal places
    // USD value should be calculated (45.23 * 150 = $6,784.50)
    expect(screen.getByText('≈ $6784.50')).toBeInTheDocument();
  });

  test('shows loading state', () => {
    render(<SOLBalance balance={0} loading={true} />);

    // In loading state, SOLBalance shows "---" instead of a loading message
    expect(screen.getAllByText('---').length).toBeGreaterThan(0);
  });

  test('displays correct buttons', () => {
    render(<SOLBalance balance={45.23} loading={false} />);

    expect(screen.getByText('接收')).toBeInTheDocument();
    expect(screen.getByText('发送')).toBeInTheDocument();
  });

  test('formats large numbers correctly', () => {
    render(<SOLBalance balance={1234.56} loading={false} />);

    expect(screen.getByText('1234.5600')).toBeInTheDocument(); // Component formats to 4 decimals
    // USD value: 1234.56 * 150 = $185,184.00
    expect(screen.getByText('≈ $185184.00')).toBeInTheDocument();
  });

  test('handles zero balance', () => {
    render(<SOLBalance balance={0} loading={false} />);

    expect(screen.getByText('0.0000')).toBeInTheDocument(); // Component formats to 4 decimals
    expect(screen.getByText('≈ $0.00')).toBeInTheDocument();
  });
});
