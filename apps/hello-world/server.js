const fastify = require('fastify')({ logger: true });
const fastifyEnv = require('fastify-env');
const path = require('path');

const schema = {
    type: 'object',
    required: ['PORT'],
    properties: {
        PORT: {
            type: 'string',
            default: 3000
        },
        pod: {
            type: 'string',
            default: 'unspecified'
        },
        node: {
            type: 'string',
            default: 'unspecified'
        },
        isAlive: {
            type: 'boolean',
            default: true
        },
        isReady: {
            type: 'boolean',
            default: true
        }
    }
}

const options = {
    confKey: 'config',
    schema: schema,
    data: process.env
}

fastify.register(require('point-of-view'), {
    engine: {
        handlebars: require('handlebars')
    },
    includeViewExtension: true
})

fastify.get('/', (req, reply) => {
    return reply.code(200).view('/views/layouts/main', {
        pod: fastify.config.pod,
        node: fastify.config.node
    });
});

fastify.get('/healthz', { logLevel: 'trace' }, (req, reply) => {
    fastify.log.trace('Trace Message');
    return reply.code(200).header('Content-Type', 'application/json; chartset=utf-8').send({ "Healthy": true });
});

fastify.get('/health/live', (req, reply) => {
    return reply.code(200).header('Content-Type', 'application/json; chartset=utf-8').send({ "Healthy": fastify.config.isAlive });
});

fastify.get('/health/ready', (req, reply) => {
    return reply.code(200).header('Content-Type', 'application/json; chartset=utf-8').send({ "Healthy": fastify.config.isReady });
});

const bootstrap = async () => {
    try {
        await fastify.register(fastifyEnv, options).ready();        
        await fastify.listen(parseInt(fastify.config.PORT), '0.0.0.0');
        fastify.log.info(`server listening on ${fastify.server.address().port}`);
    } catch (err) {
        fastify.log.error(err);
        process.exit(1);
    }
}

bootstrap();