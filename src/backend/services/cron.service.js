/**
 * Cron Service Placeholder
 */

class CronService {
  constructor() {
    this.name = 'CronService';
    this.jobs = [];
  }

  start() {
    console.log('CronService started (placeholder)');
    return true;
  }

  stop() {
    console.log('CronService stopped (placeholder)');
    return true;
  }

  addJob(name, schedule, callback) {
    this.jobs.push({ name, schedule, callback });
    console.log(`Added cron job: ${name} with schedule: ${schedule}`);
    return true;
  }

  getStatus() {
    return {
      active: true,
      jobCount: this.jobs.length,
      jobs: this.jobs.map((job) => ({
        name: job.name,
        schedule: job.schedule,
      })),
    };
  }
}

module.exports = new CronService();
