# GCCC 测试套件

GCCC项目的完整测试框架，包括前端、后端、智能合约和集成测试。

## 目录结构

```
test/
├── frontend/          # 前端测试 (已迁移)
│   ├── setup.ts       # 测试环境配置
│   ├── basic.test.ts  # 基础功能测试
│   ├── components/    # 组件测试 (待添加)
│   ├── contexts/      # Context测试 (待添加)
│   ├── utils/         # 工具函数测试 (待添加)
│   └── integration/   # 前端集成测试 (待添加)
├── backend/           # 后端测试
│   ├── unit/          # 单元测试
│   ├── integration/   # 集成测试
│   ├── api/           # API测试
│   └── README.md      # 后端测试说明
├── integration/       # 系统集成测试
│   ├── user-flows/    # 用户流程测试
│   ├── contract-integration/ # 合约集成测试
│   ├── performance/   # 性能测试
│   └── README.md      # 集成测试说明
├── e2e/              # 端到端测试 (待添加)
├── fixtures/          # 测试数据
│   ├── users.json     # 用户测试数据
│   ├── proposals.json # 提案测试数据
│   └── nfts.json      # NFT测试数据
├── helpers/           # 测试辅助工具
│   ├── setup.ts       # 测试环境设置
│   ├── mocks.ts       # Mock数据和函数
│   └── utils.ts       # 测试工具函数
└── README.md          # 本文件
```

## 测试策略

### 1. 测试金字塔
```
        E2E Tests (少量)
       /               \
  Integration Tests (适量)
 /                         \
Unit Tests (大量)           Contract Tests (适量)
```

### 2. 测试覆盖率目标
- **单元测试**: >90%
- **集成测试**: >80%
- **E2E测试**: 核心用户流程100%
- **合约测试**: 100%

## 前端测试

### 1. 技术栈
- **测试框架**: Jest
- **React测试**: React Testing Library
- **E2E测试**: Playwright
- **Mock工具**: MSW (Mock Service Worker)

### 2. 组件测试
```typescript
// frontend/components/LoginModal.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import { LoginModal } from '@/components/LoginModal';

describe('LoginModal', () => {
  it('should render login modal correctly', () => {
    render(<LoginModal isOpen={true} onClose={jest.fn()} />);
    
    expect(screen.getByText('钱包登录')).toBeInTheDocument();
    expect(screen.getByText('选择钱包')).toBeInTheDocument();
  });

  it('should handle wallet selection', () => {
    const mockOnWalletSelect = jest.fn();
    render(
      <LoginModal 
        isOpen={true} 
        onClose={jest.fn()} 
        onWalletSelect={mockOnWalletSelect} 
      />
    );
    
    fireEvent.click(screen.getByText('Phantom'));
    expect(mockOnWalletSelect).toHaveBeenCalledWith('phantom');
  });
});
```

### 3. E2E测试
```typescript
// frontend/e2e/user-login.spec.ts
import { test, expect } from '@playwright/test';

test('用户登录流程', async ({ page }) => {
  await page.goto('/');
  
  // 点击登录按钮
  await page.click('[data-testid="login-button"]');
  
  // 选择钱包
  await page.click('[data-testid="phantom-wallet"]');
  
  // 模拟钱包连接
  await page.click('[data-testid="connect-wallet"]');
  
  // 签名消息
  await page.click('[data-testid="sign-message"]');
  
  // 完成登录
  await page.click('[data-testid="complete-login"]');
  
  // 验证登录成功
  await expect(page.locator('[data-testid="user-dashboard"]')).toBeVisible();
});
```

## 后端测试

### 1. 技术栈
- **测试框架**: Jest
- **API测试**: Supertest
- **数据库**: 测试专用PostgreSQL
- **Mock工具**: Jest Mock Functions

### 2. API测试
```typescript
// backend/api/auth.test.ts
import request from 'supertest';
import app from '@/app';
import { createTestUser } from '@/test/helpers';

describe('Auth API', () => {
  describe('POST /api/auth/connect-wallet', () => {
    it('should authenticate user with valid signature', async () => {
      const testData = {
        walletAddress: '9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM',
        message: 'Sign this message to login',
        signature: 'valid_signature_here'
      };

      const response = await request(app)
        .post('/api/auth/connect-wallet')
        .send(testData)
        .expect(200);

      expect(response.body).toHaveProperty('token');
      expect(response.body).toHaveProperty('user');
      expect(response.body.user.walletAddress).toBe(testData.walletAddress);
    });

    it('should reject invalid signature', async () => {
      const testData = {
        walletAddress: '9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM',
        message: 'Sign this message to login',
        signature: 'invalid_signature'
      };

      await request(app)
        .post('/api/auth/connect-wallet')
        .send(testData)
        .expect(401);
    });
  });
});
```

### 3. 业务逻辑测试
```typescript
// backend/services/voting.service.test.ts
import { VotingService } from '@/services/voting.service';
import { createTestProposal, createTestUser } from '@/test/helpers';

describe('VotingService', () => {
  let votingService: VotingService;

  beforeEach(() => {
    votingService = new VotingService();
  });

  describe('castVote', () => {
    it('should cast vote successfully', async () => {
      const proposal = await createTestProposal();
      const user = await createTestUser();
      
      const voteData = {
        proposalId: proposal.id,
        userId: user.id,
        choice: 'yes',
        tokenAmount: 1000
      };

      const result = await votingService.castVote(voteData);
      
      expect(result).toHaveProperty('id');
      expect(result.choice).toBe('yes');
      expect(result.tokenAmount).toBe(1000);
    });

    it('should prevent double voting', async () => {
      const proposal = await createTestProposal();
      const user = await createTestUser();
      
      const voteData = {
        proposalId: proposal.id,
        userId: user.id,
        choice: 'yes',
        tokenAmount: 1000
      };

      // 第一次投票
      await votingService.castVote(voteData);
      
      // 第二次投票应该失败
      await expect(votingService.castVote(voteData))
        .rejects.toThrow('User has already voted');
    });
  });
});
```

## 智能合约测试

### 1. 测试环境
- **框架**: Anchor Test Framework
- **测试网**: Solana Localnet
- **工具**: TypeScript + Mocha

### 2. 合约测试示例
```typescript
// smart-contracts/tests/governance.test.ts
import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { GcccGovernance } from "../target/types/gccc_governance";
import { expect } from "chai";

describe("GCCC Governance", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const program = anchor.workspace.GcccGovernance as Program<GcccGovernance>;

  it("should create proposal successfully", async () => {
    const proposalAccount = anchor.web3.Keypair.generate();
    
    await program.rpc.createProposal(
      "Test Proposal",
      "This is a test proposal",
      {
        accounts: {
          proposal: proposalAccount.publicKey,
          proposer: provider.wallet.publicKey,
          systemProgram: anchor.web3.SystemProgram.programId,
        },
        signers: [proposalAccount],
      }
    );

    const proposal = await program.account.proposal.fetch(
      proposalAccount.publicKey
    );
    
    expect(proposal.title).to.equal("Test Proposal");
    expect(proposal.description).to.equal("This is a test proposal");
    expect(proposal.proposer.toString()).to.equal(
      provider.wallet.publicKey.toString()
    );
  });

  it("should cast vote successfully", async () => {
    // 先创建提案
    const proposalAccount = anchor.web3.Keypair.generate();
    await program.rpc.createProposal(
      "Test Proposal",
      "This is a test proposal",
      {
        accounts: {
          proposal: proposalAccount.publicKey,
          proposer: provider.wallet.publicKey,
          systemProgram: anchor.web3.SystemProgram.programId,
        },
        signers: [proposalAccount],
      }
    );

    // 投票
    const voteAccount = anchor.web3.Keypair.generate();
    await program.rpc.castVote(
      true, // yes vote
      new anchor.BN(1000), // voting power
      {
        accounts: {
          vote: voteAccount.publicKey,
          proposal: proposalAccount.publicKey,
          voter: provider.wallet.publicKey,
          systemProgram: anchor.web3.SystemProgram.programId,
        },
        signers: [voteAccount],
      }
    );

    const vote = await program.account.vote.fetch(voteAccount.publicKey);
    expect(vote.choice.yes).to.not.be.undefined;
    expect(vote.votingPower.toNumber()).to.equal(1000);
  });
});
```

## 集成测试

### 1. 用户流程测试
```typescript
// integration/user-flows/complete-voting-flow.test.ts
import { setupTestEnvironment, cleanupTestEnvironment } from '@/test/helpers/setup';

describe('Complete Voting Flow', () => {
  let testEnv: TestEnvironment;

  beforeAll(async () => {
    testEnv = await setupTestEnvironment();
  });

  afterAll(async () => {
    await cleanupTestEnvironment(testEnv);
  });

  it('should complete full voting flow', async () => {
    // 1. 用户连接钱包
    const user = await testEnv.connectWallet();
    
    // 2. 创建提案
    const proposal = await testEnv.createProposal({
      title: 'Test Proposal',
      description: 'Integration test proposal',
      creator: user.id
    });
    
    // 3. 质押代币获得投票权
    await testEnv.stakeTokens(user.id, 1000);
    
    // 4. 投票
    const vote = await testEnv.castVote({
      proposalId: proposal.id,
      userId: user.id,
      choice: 'yes',
      tokenAmount: 500
    });
    
    // 5. 验证投票结果
    const updatedProposal = await testEnv.getProposal(proposal.id);
    expect(updatedProposal.yesVotes).toBe(1);
    expect(updatedProposal.yesTokens).toBe(500);
    
    // 6. 验证链上状态
    const onChainVote = await testEnv.getOnChainVote(vote.transactionHash);
    expect(onChainVote.choice).toBe('yes');
  });
});
```

### 2. 性能测试
```typescript
// integration/performance/load.test.ts
import { performance } from 'perf_hooks';

describe('Performance Tests', () => {
  it('should handle concurrent voting', async () => {
    const proposal = await createTestProposal();
    const users = await createTestUsers(100);
    
    const startTime = performance.now();
    
    // 并发投票
    const promises = users.map(user => 
      castVote({
        proposalId: proposal.id,
        userId: user.id,
        choice: Math.random() > 0.5 ? 'yes' : 'no',
        tokenAmount: 100
      })
    );
    
    await Promise.all(promises);
    
    const endTime = performance.now();
    const duration = endTime - startTime;
    
    // 验证性能指标
    expect(duration).toBeLessThan(10000); // 10秒内完成
    
    // 验证数据一致性
    const updatedProposal = await getProposal(proposal.id);
    expect(updatedProposal.totalVotes).toBe(100);
  });
});
```

## 测试数据管理

### 1. Fixtures
```json
// fixtures/users.json
{
  "testUsers": [
    {
      "walletAddress": "9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM",
      "username": "testuser1",
      "email": "test1@example.com",
      "level": 1,
      "experience": 100
    },
    {
      "walletAddress": "FhYXQVFJ8kKvVRN7VdtqwXgF3nQhWGtKdLm5YWnPcDnv",
      "username": "testuser2",
      "email": "test2@example.com",
      "level": 2,
      "experience": 250
    }
  ]
}
```

### 2. Mock数据生成
```typescript
// helpers/mocks.ts
export function createMockUser(overrides: Partial<User> = {}): User {
  return {
    id: generateUUID(),
    walletAddress: generateSolanaAddress(),
    username: faker.internet.userName(),
    email: faker.internet.email(),
    level: faker.number.int({ min: 1, max: 10 }),
    experience: faker.number.int({ min: 0, max: 1000 }),
    kycStatus: 'verified',
    referralCode: generateReferralCode(),
    createdAt: new Date(),
    updatedAt: new Date(),
    ...overrides
  };
}
```

## 测试环境配置

### 1. Jest配置
```javascript
// jest.config.js
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src', '<rootDir>/test'],
  testMatch: ['**/__tests__/**/*.ts', '**/?(*.)+(spec|test).ts'],
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.d.ts',
    '!src/test/**/*'
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    }
  },
  setupFilesAfterEnv: ['<rootDir>/test/helpers/setup.ts']
};
```

### 2. 数据库测试配置
```typescript
// helpers/setup.ts
export async function setupTestDatabase() {
  // 创建测试数据库
  await createTestDatabase();
  
  // 运行迁移
  await runMigrations();
  
  // 清理数据
  await cleanDatabase();
}

export async function teardownTestDatabase() {
  await dropTestDatabase();
}
```

## CI/CD集成

### 1. GitHub Actions
```yaml
# .github/workflows/test.yml
name: Test Suite

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_PASSWORD: test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          
      - name: Install dependencies
        run: npm ci
        
      - name: Run unit tests
        run: npm run test:unit
        
      - name: Run integration tests
        run: npm run test:integration
        
      - name: Upload coverage
        uses: codecov/codecov-action@v3
```

### 2. 测试报告
- 覆盖率报告自动生成
- 测试结果可视化
- 性能基准跟踪
- 失败测试告警

## 最佳实践

### 1. 测试编写原则
- AAA模式：Arrange, Act, Assert
- 独立性：测试间不相互依赖
- 可重复性：每次运行结果一致
- 快速反馈：测试执行时间短

### 2. Mock策略
- 外部服务Mock
- 数据库操作Mock
- 时间相关Mock
- 随机数Mock

### 3. 数据隔离
- 每个测试独立数据
- 测试后自动清理
- 并行测试支持
- 事务回滚机制
