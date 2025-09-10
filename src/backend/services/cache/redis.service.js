/**
 * Redis Service Placeholder
 */

class RedisService {
  constructor() {
    this.name = 'RedisService';
    this.isConnected = false;
  }

  async connect() {
    this.isConnected = true;
    return true;
  }

  async disconnect() {
    this.isConnected = false;
    return true;
  }

  async ping() {
    return 'PONG';
  }

  async get(key) {
    return null;
  }

  async set(key, value, ttl = 3600) {
    return 'OK';
  }

  async delete(key) {
    return true;
  }

  getStatus() {
    return {
      connected: this.isConnected,
      status: 'healthy',
    };
  }
}

module.exports = new RedisService();
