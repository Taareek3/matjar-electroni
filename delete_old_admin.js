const { PrismaClient } = require('./src/generated/prisma/client.js');
const p = new PrismaClient();

p.user.deleteMany({ where: { email: 'admin@binaflow.com' } })
  .then(r => { console.log('Deleted:', r.count); process.exit(0); })
  .catch(e => { console.error(e.message); process.exit(1); });
