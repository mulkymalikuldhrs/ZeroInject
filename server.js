import express from 'express';
import { createServer } from 'http';
import { Server } from 'socket.io';
import cors from 'cors';
import { v4 as uuidv4 } from 'uuid';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const server = createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// In-memory storage for workflows
let activeWorkflows = new Map();
let workflowHistory = [];

// Workflow templates
const workflowTemplates = {
  standard_process: {
    name: 'Standard Multi-Agent Process',
    steps: ['Planning', 'Execution', 'Review', 'Output'],
    agents: ['Agent 03 (Planner)', 'Agent 04 (Executor)', 'Agent 06 (Specialist)', 'Output Handler']
  },
  software_development: {
    name: 'Software Development Workflow',
    steps: ['Requirements', 'Design', 'Development', 'Testing', 'Deployment'],
    agents: ['Requirements Analyst', 'System Designer', 'Developer', 'QA Tester', 'DevOps Engineer']
  },
  content_creation: {
    name: 'Content Creation Workflow',
    steps: ['Research', 'Planning', 'Writing', 'Review', 'Publishing'],
    agents: ['Researcher', 'Content Planner', 'Writer', 'Editor', 'Publisher']
  },
  data_analysis: {
    name: 'Data Analysis Workflow',
    steps: ['Collection', 'Cleaning', 'Analysis', 'Visualization', 'Report'],
    agents: ['Data Collector', 'Data Cleaner', 'Analyst', 'Visualization Expert', 'Report Generator']
  }
};

// API Routes
app.get('/api/workflows/active', (req, res) => {
  const workflows = Array.from(activeWorkflows.values()).map(workflow => ({
    id: workflow.id,
    name: workflow.name,
    status: workflow.status,
    progress: workflow.progress,
    started: workflow.started,
    eta: workflow.eta,
    currentStep: workflow.currentStep
  }));
  res.json({ success: true, workflows });
});

app.get('/api/workflows/history', (req, res) => {
  res.json({ success: true, workflows: workflowHistory });
});

app.post('/api/workflows/execute', (req, res) => {
  try {
    const { workflow_name, request } = req.body;
    
    if (!workflow_name || !request) {
      return res.status(400).json({ success: false, error: 'Missing required fields' });
    }

    const template = workflowTemplates[workflow_name];
    if (!template) {
      return res.status(400).json({ success: false, error: 'Invalid workflow template' });
    }

    const workflowId = `wf_${uuidv4().substring(0, 8)}`;
    const workflow = {
      id: workflowId,
      name: request.name,
      description: request.description,
      priority: request.priority,
      template: workflow_name,
      status: 'running',
      progress: 0,
      started: new Date().toISOString(),
      eta: '5 minutes',
      currentStep: template.steps[0],
      steps: template.steps.map((step, index) => ({
        name: step,
        agent: template.agents[index],
        status: index === 0 ? 'running' : 'pending',
        duration: '-'
      })),
      logs: []
    };

    activeWorkflows.set(workflowId, workflow);

    // Emit workflow started event
    io.emit('workflow_started', {
      workflow_id: workflowId,
      workflow_name: request.name
    });

    // Simulate workflow execution
    simulateWorkflowExecution(workflowId);

    res.json({ 
      success: true, 
      workflow_id: workflowId,
      message: 'Workflow started successfully'
    });

  } catch (error) {
    console.error('Error executing workflow:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
});

app.get('/api/workflows/:id', (req, res) => {
  const workflowId = req.params.id;
  const workflow = activeWorkflows.get(workflowId) || 
                   workflowHistory.find(w => w.id === workflowId);
  
  if (!workflow) {
    return res.status(404).json({ success: false, error: 'Workflow not found' });
  }

  res.json({ success: true, workflow });
});

app.post('/api/workflows/:id/pause', (req, res) => {
  const workflowId = req.params.id;
  const workflow = activeWorkflows.get(workflowId);
  
  if (!workflow) {
    return res.status(404).json({ success: false, error: 'Workflow not found' });
  }

  workflow.status = 'paused';
  res.json({ success: true, message: 'Workflow paused' });
});

app.post('/api/workflows/:id/stop', (req, res) => {
  const workflowId = req.params.id;
  const workflow = activeWorkflows.get(workflowId);
  
  if (!workflow) {
    return res.status(404).json({ success: false, error: 'Workflow not found' });
  }

  workflow.status = 'stopped';
  workflow.completed = new Date().toISOString();
  
  // Move to history
  workflowHistory.unshift(workflow);
  activeWorkflows.delete(workflowId);

  res.json({ success: true, message: 'Workflow stopped' });
});

// Simulate workflow execution
function simulateWorkflowExecution(workflowId) {
  const workflow = activeWorkflows.get(workflowId);
  if (!workflow) return;

  let currentStepIndex = 0;
  const totalSteps = workflow.steps.length;

  const executeStep = () => {
    if (currentStepIndex >= totalSteps || workflow.status !== 'running') {
      // Workflow completed
      workflow.status = 'completed';
      workflow.progress = 100;
      workflow.completed = new Date().toISOString();
      workflow.duration = '3m 45s';
      workflow.results = 'Workflow completed successfully';

      // Move to history
      workflowHistory.unshift(workflow);
      activeWorkflows.delete(workflowId);

      io.emit('workflow_completed', {
        workflow_id: workflowId,
        workflow_name: workflow.name
      });

      return;
    }

    const step = workflow.steps[currentStepIndex];
    step.status = 'running';
    workflow.currentStep = step.name;
    workflow.progress = Math.round(((currentStepIndex + 0.5) / totalSteps) * 100);

    // Add log entry
    workflow.logs.push({
      timestamp: new Date().toISOString(),
      step: `${currentStepIndex + 1}. ${step.name}`,
      agent: step.agent,
      status: 'running',
      message: `Started ${step.name.toLowerCase()}...`
    });

    io.emit('workflow_step_started', {
      workflow_id: workflowId,
      step_index: currentStepIndex,
      step_name: step.name
    });

    // Simulate step completion after random time
    setTimeout(() => {
      if (workflow.status !== 'running') return;

      step.status = 'completed';
      step.duration = `${Math.floor(Math.random() * 120) + 30}s`;
      workflow.progress = Math.round(((currentStepIndex + 1) / totalSteps) * 100);

      // Add completion log entry
      workflow.logs.push({
        timestamp: new Date().toISOString(),
        step: `${currentStepIndex + 1}. ${step.name}`,
        agent: step.agent,
        status: 'completed',
        message: `${step.name} completed successfully`
      });

      io.emit('workflow_step_completed', {
        workflow_id: workflowId,
        step_index: currentStepIndex,
        step_name: step.name
      });

      currentStepIndex++;
      
      // Continue to next step after a short delay
      setTimeout(executeStep, 2000);
    }, Math.random() * 5000 + 3000); // 3-8 seconds per step
  };

  // Start first step after a short delay
  setTimeout(executeStep, 1000);
}

// Socket.IO connection handling
io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);

  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.id);
  });

  socket.on('subscribe_workflow', (workflowId) => {
    socket.join(`workflow_${workflowId}`);
  });

  socket.on('unsubscribe_workflow', (workflowId) => {
    socket.leave(`workflow_${workflowId}`);
  });
});

// Serve the main page
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`🚀 Agentic Workflow System running on port ${PORT}`);
  console.log(`📊 Dashboard: http://localhost:${PORT}`);
});