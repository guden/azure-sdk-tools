#!/usr/bin/env node

import { spawn } from "child_process";
import * as path from "path";
import { Logger } from "winston";
import { initializeLogger } from "@azure-tools/sdk-generation-lib";
import { dockerCliConfig, DockerCliConfig } from "./schema/dockerCliConfig";
import { dockerMockHostConfig, DockerMockHostConfig } from "./schema/mockHostCliSchema";

export type DockerMockHostContext = {
    readmeMdPath?: string;
    specRepo?: string;
    mockHostPath: string;
    logger: Logger;
}

export function initializeDockerMockHostContext(inputParams: DockerMockHostConfig & DockerCliConfig) {
    const dockerMockHostConfigProperties = dockerMockHostConfig.getProperties();
    const dockerMockHostContext: DockerMockHostContext = {
        readmeMdPath: inputParams.readmeMdPath,
        specRepo: inputParams.specRepo,
        mockHostPath: dockerMockHostConfigProperties.mockHostPath,
        logger: initializeLogger(path.join(inputParams.resultOutputFolder, dockerMockHostConfigProperties.mockHostLogger), 'mock-host', false),
    }
    return dockerMockHostContext;
}

export function runMockHost() {
    const inputParams: DockerMockHostConfig & DockerCliConfig = {
        ...dockerCliConfig.getProperties(),
        ...dockerMockHostConfig.getProperties()
    }
    const context = initializeDockerMockHostContext(inputParams);
    if (!context.readmeMdPath) {
        context.logger.log('cmdout', `Cannot get valid readme, so do not start mock server.`);
        return;
    }
    const swaggerJsonFilePattern = context.readmeMdPath.replace(/readme[.a-z-]*.md/gi, '**/*.json');
    const child = spawn(`node`,[`node_modules/@azure-tools/mock-service-host/dist/src/main.js`], {
        cwd: context.mockHostPath,
        env: {
            ...process.env,
            'specRetrievalMethod': 'filesystem',
            'specRetrievalLocalRelativePath': context.specRepo,
            'validationPathsPattern': swaggerJsonFilePattern
        },
    });
    child.stdout.on('data', data => context.logger.log('cmdout', data.toString()));
    child.stderr.on('data', data => context.logger.log('cmderr', data.toString()));
}

runMockHost();