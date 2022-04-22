import convict from 'convict';
import * as dotenv from 'dotenv';

dotenv.config();

export class UserInterfaceEntrypoint {
    readmeMdPath: string;
    tag: string;
    sdkToGenerate: string;
    specRepo: string;
    workDir: string;
    sdkRepo: string;
    resultOutputFolder: string;
    dockerLogger: string;
}

export const userInterfaceEntrypoint = convict<UserInterfaceEntrypoint>({
    readmeMdPath: {
        default: '',
        env: 'README_MD_PATH',
        arg: 'readme',
        format: String,
        doc: 'The relative path to readme.md, which is from the root of spec repo'
    },
    tag: {
        default: '',
        env: 'TAG',
        arg: 'tag',
        format: String,
        doc: 'The tag used to generated codes. If not defined, default tag will be used'
    },
    sdkToGenerate: {
        default: '',
        env: 'SDK_TO_GENERATE',
        arg: 'sdk-to-generate',
        format: String,
        doc: 'which language of sdks do you want to generate? you can input multi language splitted by comma'
    },
    specRepo: {
        default: '/spec-repo',
        env: 'SPEC_REPO',
        arg: 'spec-repo',
        format: String,
        doc: 'the absolute path of the mounted spec repo'
    },
    workDir: {
        default: '/work-dir',
        env: 'WORK_DIR',
        arg: 'work-dir',
        format: String,
        doc: 'the absolute path of work directory, which contains all sdk repos'
    },
    sdkRepo: {
        default: '/sdk-repo',
        env: 'SDK_REPO',
        arg: 'sdk-repo',
        format: String,
        doc: 'the absolute path of sdk repo'
    },
    resultOutputFolder: {
        default: '/tmp/output',
        env: 'RESULT_OUTPUT_FOLDER',
        arg: 'result-output-folder',
        format: String,
        doc: 'the absolute path of output folder, which stores the result of task engine'
    },
    dockerLogger: {
        default: 'docker.log',
        env: 'DOCKER_LOGGER',
        arg: 'docker-logger',
        format: String,
        doc: 'the path of docker.log. it will concat with resultOutputFolder'
    }
});
