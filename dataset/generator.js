const fs = require("fs");

const departments = [
    "Computer Science",
    "Information Technology",
    "Cyber Security",
    "Artificial Intelligence",
    "Data Science"
];

const coursePool = [
    101,102,103,104,105,
    201,202,203,204,205,
    301,302,303,304,305
];

function randomDepartment() {
    return departments[Math.floor(Math.random() * departments.length)];
}

function randomCourses() {
    let courses = [];

    while (courses.length < 5) {

        let c = coursePool[Math.floor(Math.random() * coursePool.length)];

        if (!courses.includes(c))
            courses.push(c);
    }

    return courses;
}

function generateDataset(size) {

    let students = [];

    for (let i = 1; i <= size; i++) {

        students.push({

            studentId: "STU" + String(i).padStart(4, "0"),

            name: "Student_" + i,

            department: randomDepartment(),

            semester: Math.floor(Math.random() * 8) + 1,

            credits: Math.floor(Math.random() * 80) + 40,

            cgpa: (6 + Math.random() * 4).toFixed(2),

            degreeStatus:
                Math.random() > 0.8
                    ? "Graduated"
                    : "Active",

            courseIds: randomCourses()

        });

    }

    fs.writeFileSync(

        `dataset/students_${size}.json`,

        JSON.stringify(students, null, 2)

    );

    console.log(`Generated students_${size}.json`);

}

generateDataset(100);
generateDataset(250);
generateDataset(500);
generateDataset(750);
generateDataset(1000);