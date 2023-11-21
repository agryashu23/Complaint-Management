const admin = require('firebase-admin');
const express = require('express');
const bodyParser = require('body-parser');
const bcrypt = require('bcrypt');
const cron = require('node-cron');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const request = require('request');
const multer = require('multer');
var path = require('path');

const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const API_KEY = 'AIzaSyC1A7zM67k09UeHvPcf0DJo_OHcx9pdwQc';

const secret = 'THISISMYSECRETKEY';
const app = express();
app.set('view engine', 'jade');
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());
app.use(express.static(path.join(__dirname, 'public')));
app.use(express.static(path.join(__dirname, 'build')));
app.use('/uploads', express.static(__dirname + '/uploads'));
app.use(function (req, res, next) {
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Methods", "GET,HEAD,OPTIONS,PUT,POST,PATCH,DELETE");
    res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept, Authorization");
    next();
});

mongoose.connect('', {
    useNewUrlParser: true,
    useUnifiedTopology: true
}).then(() => {
    console.log('Connected to MongoDB');
}).catch((error) => {
    console.log(error);
    console.log('Not connected to MongoDB');
})

// Define storage for uploaded files
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, 'uploads/'); // Destination folder for uploaded files
    },
    filename: function (req, file, cb) {
        cb(null, Date.now() + '-' + file.originalname); // Set filename with timestamp
    }
});

// Create an instance of Multer
const upload = multer({ storage: storage });

const userSchema = new mongoose.Schema({
    email: String,
    password: String,
    name: String,
    mobile: String
});

const customerSchema = new mongoose.Schema({
    mobileNumber: {
        type: String,
        default: '',
        unique: true
    },
    firebaseUid: String,
    name: {
        type: String,
        default: ''
    },
    email: {
        type: String,
        default: ''
    },
    phone: {
        type: String,
        default: '',
        unique: true
    },
    address: {
        type: String,
        default: ''
    },
    city: {
        type: String,
        default: ''
    },
    latitude: {
        type: String,
        default: ''
    },
    longitude: {
        type: String,
        default: ''
    },
    pincode: {
        type: String,
        default: ''
    },
    type: {
        type: String,
        default: 'user'
    }
});

const notificationEventSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Customer',
        required: true,
    },
    complaint: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Complaint',
        required: true,
    },
    type: {
        type: String,
    },
    status: {
        type: Number
    },
    message: {
        type: String
    },
    time: {
        type: Date,
    },
    title: { type: String, default: '' },
});

const complaintSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Customer',
        required: true,
    },
    verification: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Customer',
    },
    contractor: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Customer',
    },
    title: {
        type: String,
    },
    address: {
        type: String,
    },
    latitude: {
        type: String,
    },
    longitude: {
        type: String,
    },
    images: [{
        type: String, // You can store the image URLs or file paths
        required: true
    }],
    description: {
        type: String,
        required: true,
    },
    timestamp: {
        type: Date,
        default: Date.now,
    },
    status: {
        type: String,
        enum: ['pending', 'verification', 'verified', 'inProgress', 'resolved', 'fake'],
        default: 'pending'
    },
});

const complaintStatusSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Customer',
        required: true,
    },
    complaint: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Complaint',
        required: true,
    },
    title: {
        type: String,
    },
    description: {
        type: String,
    },
    images: [{
        type: String,
    }],
    timestamp: {
        type: Date,
        default: Date.now,
    },
    status: {
        type: String,
        enum: ['verification', 'inProgress', 'checking'],
    },
});

const User = mongoose.model('User', userSchema);
const Complaint = mongoose.model('Complaint', complaintSchema);
const ComplaintStatus = mongoose.model('ComplaintStatus', complaintStatusSchema);
const NotificationEvent = mongoose.model('NotificationEvent', notificationEventSchema);
const Customer = mongoose.model('Customer', customerSchema);

cron.schedule('*/5 * * * * *', async () => {
    const result = await NotificationEvent.find({ status: -1 }).exec();
    for (let index = 0; index < result.length; index++) {
        const element = result[index];
        try {
            var options = {
                'method': 'POST',
                'url': 'https://onesignal.com/api/v1/notifications',
                'headers': {
                    'Authorization': 'Basic MWQ5YjBjNjgtMTMwYi00ODdjLTlhYTMtNGJhNjFiNThjOGEw',
                    'accept': 'application/json',
                    'content-type': 'application/json',
                },
                body: JSON.stringify({
                    "app_id": "5ca16c48-886d-4653-a290-b768d007a4c0",
                    "include_external_user_ids": [
                        element.user,
                    ],
                    "contents": {
                        "en": element.message,
                    },
                    "name": "INTERNAL_CAMPAIGN_NAME"
                })
            };
            request(options, async function (error, response) {
                if (error) throw new Error(error);
                await NotificationEvent.findByIdAndUpdate(element.id, { status: 1 }).exec();
            });
        } catch (e) {
            console.log(e);
        }
    }
});

app.post('/admin/register', async (req, res) => {
    const { email, password, name, mobile } = req.body;
    const user = await User.findOne({ email });
    if (user) {
        return res.status(409).json({ message: 'Email already taken', success: false });
    }
    const hashedPassword = await bcrypt.hash(password, 10);
    const newUser = new User({ email, password: hashedPassword, mobile: mobile, name: name });
    await newUser.save();
    res.status(201).json({ message: 'User created', success: true });
});

app.post('/admin/login', async (req, res) => {
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    if (!user) {
        return res.status(401).json({ message: 'Invalid email or password', success: false });
    }
    const passwordMatch = await bcrypt.compare(password, user.password);
    if (!passwordMatch) {
        return res.status(401).json({ message: 'Invalid email or password', success: false });
    }
    const token = jwt.sign({ email: user.email }, secret, { expiresIn: '1h' });
    res.status(200).json({ message: 'Logged in successfully', token, success: true, type: 'admin' });
});

app.post('/mobile/complaints', upload.array('images', 5), async (req, res) => {
    try {
        const { user, title, address, latitude, longitude, description } = req.body;
        const images = req.files.map(file => file.path);
        const complaint = new Complaint({
            user,
            title,
            images,
            description,
            address,
            latitude,
            longitude,
        });
        await complaint.save();
        res.status(201).json(complaint);
    } catch (error) {
        console.log(error);
        res.status(500).json({ error: 'An error occurred while creating the complaint.' });
    }
});

app.post('/mobile/verify-complaints', upload.array('images', 5), async (req, res) => {
    try {
        const { user, complaint, title, description } = req.body;
        const images = req.files.map(file => file.path);
        const complaintStatus = new ComplaintStatus({
            user,
            complaint,
            title,
            images,
            description,
            status: 'verification',
        });
        await complaintStatus.save();
        const response = await Complaint.findById(complaint).populate('user');
        notification = new NotificationEvent({
            type: 'custom',
            user: response.user._id,
            complaint,
            title: 'Verification',
            sendIDs: '',
            message: 'Your complain is under verification.',
            status: -1,
            time: new Date()
        });
        await notification.save();
        const complaintModification = await Complaint.findByIdAndUpdate(complaint, { status: 'verified' }, { new: true });
        if (!complaint) {
            return res.status(404).json({ error: 'Complaint not found.' });
        }
        res.json(complaintModification);
    } catch (error) {
        console.log(error);
        res.status(500).json({ error: 'An error occurred while creating the complaint.' });
    }
});

app.post('/mobile/repaired-complaints', upload.array('images', 5), async (req, res) => {
    try {
        const { user, complaint, title, description } = req.body;
        const images = req.files.map(file => file.path);
        const complaintStatus = new ComplaintStatus({
            user,
            complaint,
            title,
            images,
            description,
            status: 'inProgress',
        });
        await complaintStatus.save();
        const response = await Complaint.findById(complaint).populate('user');
        notification = new NotificationEvent({
            type: 'custom',
            user: response.user._id,
            complaint,
            title: 'Progress',
            sendIDs: '',
            message: 'Your complain is under progress.',
            status: -1,
            time: new Date()
        });
        await notification.save();
        const complaintModification = await Complaint.findByIdAndUpdate(complaint, { status: 'verification' }, { new: true });
        if (!complaint) {
            return res.status(404).json({ error: 'Complaint not found.' });
        }
        res.json(complaintModification);
    } catch (error) {
        res.status(500).json({ error: 'An error occurred while creating the complaint.' });
    }
});

function capitalizeFirstLetter(string) {
    return string.charAt(0).toUpperCase() + string.slice(1);
}

app.patch('/complaints/:id', async (req, res) => {
    try {
        const complaint = await Complaint.findByIdAndUpdate(req.params.id, req.body, { new: true });
        if (!complaint) {
            return res.status(404).json({ error: 'Complaint not found.' });
        }
        const response = await Complaint.findById(req.params.id).populate('user');
        notification = new NotificationEvent({
            type: 'custom',
            user: response.user._id,
            complaint: req.params.id,
            title: `${capitalizeFirstLetter(req.body.status)}`,
            sendIDs: '',
            message: `Your complain is under ${req.body.status}.`,
            status: -1,
            time: new Date()
        });
        await notification.save();
        res.json(complaint);
    } catch (error) {
        console.log(error);
        res.status(500).json({ error: 'Failed to update complaint.' });
    }
});

app.get('/mobile/complaints', async (req, res) => {
    try {
        const complaints = await Complaint.find().populate('user').exec();
        res.json(complaints);
    } catch (error) {
        res.status(500).json({ error: 'An error occurred while retrieving the complaints.' });
    }
});

app.get('/mobile/contract-complaints/:uid', async (req, res) => {
    try {
        const { uid } = req.params;
        const complaint = await Complaint.find({ contractor: uid }).populate('user').exec();
        const complaints = [];
        for (let index = 0; index < complaint.length; index++) {
            const element = complaint[index];
            const complaintStatus = await ComplaintStatus.find({ complaint: element._id }).populate('user').exec();
            if (complaintStatus.length > 0) {
                element.images = complaintStatus[complaintStatus.length - 1].images;
            }
            complaints.push(element);
        }
        if (!complaint) {
            return res.status(404).json({ error: 'Complaint not found.' });
        }
        res.json(complaints);
    } catch (error) {
        res.status(500).json({ error: 'An error occurred while retrieving the complaint.' });
    }
});

app.get('/mobile/verify-complaints/:uid', async (req, res) => {
    try {
        const { uid } = req.params;
        const complaint = await Complaint.find({ verification: uid }).populate('user').exec();
        const complaints = [];
        for (let index = 0; index < complaint.length; index++) {
            const element = complaint[index];
            const complaintStatus = await ComplaintStatus.find({ complaint: element._id }).populate('user').exec();
            if (complaintStatus.length > 0) {
                element.images = complaintStatus[complaintStatus.length - 1].images;
            }
            complaints.push(element);
        }
        if (!complaint) {
            return res.status(404).json({ error: 'Complaint not found.' });
        }
        res.json(complaints);
    } catch (error) {
        res.status(500).json({ error: 'An error occurred while retrieving the complaint.' });
    }
});

app.get('/mobile/contracterlist-complaints/:uid', async (req, res) => {
    try {
        const { uid } = req.params;
        const complaint = await Complaint.find({ contractor: uid }).populate('user').exec();
        const complaints = [];
        for (let index = 0; index < complaint.length; index++) {
            const element = complaint[index];
            const complaintStatus = await ComplaintStatus.find({ complaint: element._id }).populate('user').exec();
            if (complaintStatus.length > 0) {
                element.images = complaintStatus[complaintStatus.length - 1].images;
            }
            complaints.push(element);
        }
        if (!complaint) {
            return res.status(404).json({ error: 'Complaint not found.' });
        }
        res.json(complaints);
    } catch (error) {
        res.status(500).json({ error: 'An error occurred while retrieving the complaint.' });
    }
});

app.get('/mobile/verify-complaints-status/:uid', async (req, res) => {
    try {
        const { uid } = req.params;
        const complaint = await ComplaintStatus.find({ complaint: uid }).populate('user').exec();
        if (!complaint) {
            return res.status(404).json({ error: 'Complaint not found.' });
        }
        res.json(complaint);
    } catch (error) {
        res.status(500).json({ error: 'An error occurred while retrieving the complaint.' });
    }
});

app.get('/mobile/notifications/:userId', async (req, res) => {
    try {
        const userId = req.params.userId;

        // Query the database to find notifications for the specified user
        const notifications = await NotificationEvent.find({ user: userId });

        res.json(notifications);
    } catch (error) {
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

app.get('/mobile/complaints/:uid', async (req, res) => {
    try {
        const { uid } = req.params;
        const complaint = await Complaint.find({ user: uid }).populate('user').exec();
        const complaints = [];
        for (let index = 0; index < complaint.length; index++) {
            const element = complaint[index];
            const complaintStatus = await ComplaintStatus.find({ complaint: element._id }).populate('user').exec();
            if (complaintStatus.length > 0) {
                element.images = complaintStatus[complaintStatus.length - 1].images;
            }
            complaints.push(element);
        }
        if (!complaint) {
            return res.status(404).json({ error: 'Complaint not found.' });
        }
        res.json(complaints);
    } catch (error) {
        res.status(500).json({ error: 'An error occurred while retrieving the complaint.' });
    }
});

app.patch('/mobile/complaints/:uid', async (req, res) => {
    try {
        const { uid } = req.params;
        const { status } = req.body;
        const complaint = await Complaint.findByIdAndUpdate(uid, { status }, { new: true });
        if (!complaint) {
            return res.status(404).json({ error: 'Complaint not found.' });
        }
        res.json(complaint);
    } catch (error) {
        res.status(500).json({ error: 'An error occurred while updating the complaint.' });
    }
});

app.delete('/mobile/complaints/:uid', async (req, res) => {
    try {
        const { uid } = req.params;
        const complaint = await Complaint.findByIdAndDelete(uid);
        if (!complaint) {
            return res.status(404).json({ error: 'Complaint not found.' });
        }
        res.json({ message: 'Complaint deleted successfully.' });
    } catch (error) {
        res.status(500).json({ error: 'An error occurred while deleting the complaint.' });
    }
});

app.post('/complaint-status', async (req, res) => {
    try {
        const complaintStatus = await ComplaintStatus.create(req.body);
        res.status(201).json(complaintStatus);
    } catch (error) {
        res.status(400).json({ error: 'Failed to create complaint status.' });
    }
});

app.post('/complaint-status-verify', upload.array('images', 5), async (req, res) => {
    try {
        const { user, complaint, title, description } = req.body;

        // Check if required fields are provided
        if (!user || !complaint || !title || !description) {
            return res.status(400).json({ error: 'Missing required fields.' });
        }

        // Check if the complaint exists
        const existingComplaint = await Complaint.findById(complaint);
        if (!existingComplaint) {
            return res.status(404).json({ error: 'Complaint not found.' });
        }

        // Extract image paths from uploaded files
        const images = req.files.map(file => file.path);

        // Create the complaint status
        const complaintStatus = new ComplaintStatus({
            user,
            complaint,
            title,
            images,
            description,
            status: 'verification'
        });
        const response = await Complaint.findById(complaint).populate('user');
        notification = new NotificationEvent({
            type: 'custom',
            user: response.user._id,
            complaint,
            title: 'Verification',
            sendIDs: '',
            message: 'Your complain is under verification.',
            status: -1,
            time: new Date()
        });
        await notification.save();
        // Save the complaint status to the database
        await complaintStatus.save();

        // Update the complaint status to 'verified'
        existingComplaint.status = 'verified';
        await existingComplaint.save();

        res.status(201).json(existingComplaint);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'An error occurred while creating the complaint.' });
    }
});

app.get('/complaint-status', async (req, res) => {
    try {
        const complaintStatuses = await ComplaintStatus.find();
        res.json(complaintStatuses);
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch complaint statuses.' });
    }
});

app.get('/complaint-status/:id', async (req, res) => {
    try {
        const complaintStatus = await ComplaintStatus.findById(req.params.id);
        if (!complaintStatus) {
            return res.status(404).json({ error: 'Complaint status not found.' });
        }
        res.json(complaintStatus);
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch complaint status.' });
    }
});

app.patch('/complaint-status/:id', async (req, res) => {
    try {
        const complaintStatus = await ComplaintStatus.findByIdAndUpdate(req.params.id, req.body, { new: true });
        if (!complaintStatus) {
            return res.status(404).json({ error: 'Complaint status not found.' });
        }
        res.json(complaintStatus);
    } catch (error) {
        res.status(500).json({ error: 'Failed to update complaint status.' });
    }
});

app.delete('/complaint-status/:id', async (req, res) => {
    try {
        const complaintStatus = await ComplaintStatus.findByIdAndDelete(req.params.id);
        if (!complaintStatus) {
            return res.status(404).json({ error: 'Complaint status not found.' });
        }
        res.json({ message: 'Complaint status deleted successfully.' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to delete complaint status.' });
    }
});


app.post('/api/custom-notification/:id', async (req, res) => {
    const { id } = req.params;
    const { title, message, sendIDs } = req.body;
    try {
        notification = new NotificationEvent({
            type: 'custom',
            user: id,
            title: title,
            sendIDs: sendIDs,
            message: message,
            status: -1,
            time: new Date()
        });
        await notification.save((err) => {
            if (err) {
                res.status(500).send('Error saving attendance record');
                return;
            }
        });
        res.status(201).json({ success: true, error: 'Notification sent successfully.' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Register a new user
app.post('/mobile/login', (req, res) => {
    const mobileNumber = req.body.mobileNumber;
    console.log(mobileNumber);
    if (!mobileNumber) {
        return res.status(400).json({ error: 'Mobile number is required' });
    }
    Customer.findOne({ mobileNumber: mobileNumber })
        .then(async (customer) => {
            console.log(customer);
            if (!customer) {
                // admin.auth().createUser({ phoneNumber: mobileNumber })
                //     .then(customerRecord => {

                //     })


                // })
                //     .catch(error => res.status(500).json({ error: 'Failed to register customer', details: error }));
                const customer = new Customer({
                    mobileNumber: mobileNumber,
                    // firebaseUid: customerRecord.uid
                    firebaseUid: '',
                    type: 'user'
                });
                await customer.save().then(customer => {
                    return res.status(200).json({ customer });
                }).catch(error => res.status(500).json({ error: 'Failed to find customer', details: error }));
            }
            else {
                admin.auth().getUserByPhoneNumber(customer.mobileNumber).then(() => res.status(200).json({ customer }))
                    .catch(error => res.status(500).json({ error: 'Failed to send login link', details: error }));
            }
        })
        .catch(error => res.status(500).json({ error: 'Failed to find customer', details: error }));
});

app.post('/admin/register-verify-agent', (req, res) => {
    const mobileNumber = '+91' + req.body.mobileNumber;
    const pincode = req.body.pincode;
    if (!mobileNumber) {
        return res.status(400).json({ error: 'Mobile number is required' });
    }
    Customer.findOne({ mobileNumber: mobileNumber })
        .then(async (customer) => {
            if (!customer) {
                const url = `https://maps.googleapis.com/maps/api/place/textsearch/json?query=${pincode}&key=${API_KEY}`;
                console.log(url);
                await request(url, async (error, response, body) => {
                    if (!error && response.statusCode === 200) {
                        const data = JSON.parse(body).results[0];
                        const latitude = data.geometry.location.lat;
                        const longitude = data.geometry.location.lng;
                        const customer = new Customer({
                            mobileNumber: mobileNumber,
                            firebaseUid: '',
                            name: req.body.name,
                            email: req.body.email,
                            address: req.body.address,
                            city: req.body.city,
                            pincode: pincode,
                            phone: mobileNumber,
                            latitude: latitude,
                            longitude: longitude,
                            type: 'verify'
                        });
                        await customer.save().then(customer => {
                            return res.status(200).json({ customer });
                        }).catch(error => res.status(500).json({ error: 'Failed to find customer', details: error }));
                    } else {
                        res.status(500).json({ error: 'Some error occured.' });
                    }
                });

            }
            else {
                admin.auth().getUserByPhoneNumber(customer.mobileNumber).then(() => res.status(200).json({ customer }))
                    .catch(error => res.status(500).json({ error: 'Failed to send login link', details: error }));
            }
        })
        .catch(error => res.status(500).json({ error: 'Failed to find customer', details: error }));
});

app.post('/admin/register-contractor', (req, res) => {
    const mobileNumber = '+91' + req.body.mobileNumber;
    const pincode = req.body.pincode;
    if (!mobileNumber) {
        return res.status(400).json({ error: 'Mobile number is required' });
    }
    Customer.findOne({ mobileNumber: mobileNumber })
        .then(async (customer) => {
            if (!customer) {
                const url = `https://maps.googleapis.com/maps/api/place/textsearch/json?query=${pincode}&key=${API_KEY}`;
                console.log(url);
                await request(url, async (error, response, body) => {
                    if (!error && response.statusCode === 200) {
                        const data = JSON.parse(body).results[0];
                        const latitude = data.geometry.location.lat;
                        const longitude = data.geometry.location.lng;
                        const customer = new Customer({
                            mobileNumber: mobileNumber,
                            firebaseUid: '',
                            name: req.body.name,
                            email: req.body.email,
                            address: req.body.address,
                            city: req.body.city,
                            pincode: pincode,
                            phone: mobileNumber,
                            latitude: latitude,
                            longitude: longitude,
                            type: 'contract'
                        });
                        await customer.save().then(customer => {
                            return res.status(200).json({ customer });
                        }).catch(error => res.status(500).json({ error: 'Failed to find customer', details: error }));
                    } else {
                        res.status(500).json({ error: 'Some error occured.' });
                    }
                });

            }
            else {
                admin.auth().getUserByPhoneNumber(customer.mobileNumber).then(() => res.status(200).json({ customer }))
                    .catch(error => res.status(500).json({ error: 'Failed to send login link', details: error }));
            }
        })
        .catch(error => res.status(500).json({ error: 'Failed to find customer', details: error }));
});

app.get('/customers', async (req, res) => {
    try {
        const customers = await Customer.find();
        res.json(customers);
    } catch (error) {
        res.status(500).json({ error: 'An error occurred while retrieving the customers.' });
    }
});

app.get('/mobile/customers/:uid', async (req, res) => {
    try {
        const { uid } = req.params;
        const customer = await Customer.findById(uid);
        if (!customer) {
            return res.status(404).json({ error: 'Customer not found.' });
        }
        res.json(customer);
    } catch (error) {
        res.status(500).json({ error: 'An error occurred while retrieving the customer.' });
    }
});

app.patch('/mobile/customers/:uid', async (req, res) => {
    try {
        const { uid } = req.params;
        const customer = await Customer.findByIdAndUpdate(uid, req.body, { new: true });
        if (!customer) {
            return res.status(404).json({ error: 'Customer not found.' });
        }
        res.json(customer);
    } catch (error) {
        res.status(500).json({ error: 'An error occurred while updating the customer.' });
    }
});

app.delete('/mobile/customers/:uid', async (req, res) => {
    try {
        const { uid } = req.params;
        const customer = await Customer.findByIdAndDelete(uid);
        if (!customer) {
            return res.status(404).json({ error: 'Customer not found.' });
        }
        res.json({ message: 'Customer deleted successfully.' });
    } catch (error) {
        res.status(500).json({ error: 'An error occurred while deleting the customer.' });
    }
});


// Middleware for authenticating JWT
function authenticateToken(req, res, next) {
    const authHeader = req.headers.authorization;
    const token = authHeader && authHeader.split(' ')[1];
    if (!token) {
        return res.status(401).json({ message: 'Unauthorized' });
    }
    jwt.verify(token, secret, (err, user) => {
        if (err) {
            return res.status(401).json({ message: 'Unauthorized' });
        }
        req.user = user;
        req.userID = user.email;
        next();
    });
}

// Start the server
app.listen(3000, () => {
    console.log('Server is listening on port 3000');
});
