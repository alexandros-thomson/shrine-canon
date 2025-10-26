module.exports = {
  apps: [
    {
      name: "trinity-orchestrator",
      script: "./trinity-eternal-automation.js",
      instances: 1,
      exec_mode: "fork",
      watch: false,
      autorestart: true,
      max_restarts: 5,
      restart_delay: 4000,
      time: true,
      log_date_format: "YYYY-MM-DD HH:mm:ss",
      error_file: "./logs/trinity-error.log",
      out_file: "./logs/trinity-out.log",
      merge_logs: true,
      env: {
        NODE_ENV: "development",
        ZEUS_APP_ID: process.env.ZEUS_APP_ID,
        ZEUS_APP_SECRET: process.env.ZEUS_APP_SECRET,
        ZEUS_PAGE_ID: process.env.ZEUS_PAGE_ID,
        ZEUS_PAGE_TOKEN: process.env.ZEUS_PAGE_TOKEN,
        APHRODITE_IG_ID: process.env.APHRODITE_IG_ID,
        APHRODITE_THREADS_TOKEN: process.env.APHRODITE_THREADS_TOKEN,
        GLITCH_PROBABILITY: process.env.GLITCH_PROBABILITY,
        QUANTUM_SEED: process.env.QUANTUM_SEED
      },
      env_production: {
        NODE_ENV: "production",
        ZEUS_APP_ID: process.env.ZEUS_APP_ID,
        ZEUS_APP_SECRET: process.env.ZEUS_APP_SECRET,
        ZEUS_PAGE_ID: process.env.ZEUS_PAGE_ID,
        ZEUS_PAGE_TOKEN: process.env.ZEUS_PAGE_TOKEN,
        APHRODITE_IG_ID: process.env.APHRODITE_IG_ID,
        APHRODITE_THREADS_TOKEN: process.env.APHRODITE_THREADS_TOKEN,
        GLITCH_PROBABILITY: process.env.GLITCH_PROBABILITY,
        QUANTUM_SEED: process.env.QUANTUM_SEED
      }
    }
  ]
};